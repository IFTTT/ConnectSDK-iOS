//
//  ConnectionsSynchronizer.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import UIKit
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

/// Controls current running state
enum RunState: String {
    /// Currently stopped
    case stopped = "stopped"
    
    /// Currently running
    case running = "running"
    
    /// Unknown state
    case unknown = "unknown"
}

public typealias BoolClosure = (Bool) -> Void

/// A set of application lifecycle events that are used to determine whether or not a synchronization should occur for that application lifecycle event.
public struct ApplicationLifecycleSynchronizationOptions: OptionSet, CustomStringConvertible {
    public let rawValue: Int

    /// Option for the UIApplication.didEnterBackground lifecycle event
    public static let applicationDidEnterBackground = ApplicationLifecycleSynchronizationOptions(rawValue: 1 << 0)
    
    /// Option for the UIApplication.didBecomeActive lifecycle event
    public static let applicationDidBecomeActive  = ApplicationLifecycleSynchronizationOptions(rawValue: 1 << 1)

    /// Describes all supported lifecycle events
    public static let all: ApplicationLifecycleSynchronizationOptions = [.applicationDidEnterBackground, .applicationDidBecomeActive]
    
    /// Describes none of the application lifecycle events.
    public static let none: ApplicationLifecycleSynchronizationOptions = []
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var description: String {
        var strings = [String]()
        if self.contains(.applicationDidBecomeActive) {
            strings.append("ApplicationDidBecomeActive")
        }
        if self.contains(.applicationDidEnterBackground) {
            strings.append("ApplicationDidEnterBackground")
        }
        return strings.joined(separator: ",")
    }
}

/**
 Handles synchronizing events from the SDK to the backend.
 
 Uses the following mechanisms to do so:
 - Background processing
 - App lifecycle events
    - App going to background
    - App transitions to active state
 - Other events specified by `SynchronizationSource`
*/
final class ConnectionsSynchronizer {
    private let eventPublisher: EventPublisher<SynchronizationTriggerEvent>
    private let scheduler: SynchronizationScheduler
    private let location: LocationService
    private let registry: ConnectionsRegistry
    private let connectionsMonitor: ConnectionsMonitor
    private let subscribers: [SynchronizationSubscriber]
    private var state: RunState = .stopped
    
    /// Shared instance of connections synchronizer to use in starting/stopping synchronization
    static var _shared: ConnectionsSynchronizer!
    
    static func shared() -> ConnectionsSynchronizer {
        if _shared == nil {
            _shared = ConnectionsSynchronizer(lifecycleSynchronizationOptions: .all)
        }
        return _shared
    }
    
    static func setup(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {    
        guard _shared == nil else { return }
        _shared = ConnectionsSynchronizer(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
    }
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    private init(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        let regionEventsRegistry = RegionEventsRegistry()
        let connectionsRegistry = ConnectionsRegistry()
        let permissionsRequestor = PermissionsRequestor(registry: connectionsRegistry)
        let eventPublisher = EventPublisher<SynchronizationTriggerEvent>(queue: DispatchQueue.global())

        let location = LocationService(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled,
                                       regionEventsRegistry: regionEventsRegistry,
                                       connectionsRegistry: connectionsRegistry,
                                       eventPublisher: eventPublisher)
        
        let connectionsMonitor = ConnectionsMonitor(connectionsRegistry: connectionsRegistry)
        
        self.subscribers = [
            connectionsMonitor,
            permissionsRequestor,
            location
        ]
        
        let manager = SynchronizationManager(subscribers: subscribers)
        self.registry = connectionsRegistry
        self.eventPublisher = eventPublisher
        self.scheduler = SynchronizationScheduler(manager: manager, triggers: eventPublisher, lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
        self.location = location
        self.connectionsMonitor = connectionsMonitor
        
        location.start()
    }
    
    /// Can be used to force a synchronization.
    func update() {
        let event = SynchronizationTriggerEvent(source: .forceUpdate, backgroundFetchCompletionHandler: nil)
        eventPublisher.onNext(event)
    }
    
    /// Used to start the synchronization with an optional list of connection ids to monitor.
    ///
    /// - Parameters:
    ///     - connections: An optional list of connections to start monitoring.
    func activate(connections ids: [String]? = nil) {
        if let ids = ids {
            registry.addConnections(with: ids, shouldNotify: false)
            ConnectButtonController.synchronizationLog("Activated synchronization with connection ids: \(ids)")
        } else {
            ConnectButtonController.synchronizationLog("Activated synchronization")
        }
        start()
        update()
    }
    
    /// Used to deactivate and stop synchronization.
    func deactivate() {
        ConnectButtonController.synchronizationLog("Deactivated synchronization")
        stop()
    }
    
    /// Call this to start the synchronization. Safe to be called multiple times.
    private func start() {
        guard state == .stopped else { return }
        
        setupNotifications()
        performPreflightChecks()
        Keychain.resetIfNecessary(force: false)
        subscribers.forEach { $0.start() }
        scheduler.start()
        state = .running
    }
    
    /// Call this to stop the synchronization completely. Safe to be called multiple times.
    private func stop() {
        guard state == .running else { return }
        
        Keychain.resetIfNecessary(force: true)
        scheduler.stop()
        NotificationCenter.default.removeObserver(self)
        subscribers.forEach { $0.reset() }
        state = .stopped
    }
    
    /// Runs checks to see what capabilities the target currently has and prints messages to the console as required.
    private func performPreflightChecks() {
        if !Bundle.main.backgroundProcessingEnabled {
            ConnectButtonController.synchronizationLog("Background processing not enabled for this target! Enable background processing to allow Connections to get synchronized more frequently.")
        } else if Bundle.main.backgroundProcessingEnabled && !Bundle.main.containsIFTTTBackgroundProcessingIdentifier {
            ConnectButtonController.synchronizationLog("Missing IFTTT background processing task identifier. Add com.ifttt.ifttt.synchronization_scheduler to the BGTaskSchedulerPermittedIdentifiers array of the info plist for this target.")
        }
        
        if !Bundle.main.backgroundLocationEnabled {
            ConnectButtonController.synchronizationLog("Background location not enabled for this target! Enable background location to allow location updates to be delivered to the app in the background.")
        }
    }
    
    /// Peforms internal setup to allow the SDK to perform work in response to notification center notifications.
    private func setupNotifications() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(applicationDidEnterBackground),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
        }
    }
    
    /// Hook to be called when the application enters the background.
    @objc private func applicationDidEnterBackground() {
        scheduler.applicationDidEnterBackground()
    }
    
    /// Call this to setup background processes. Must be called before the application finishes launching.
    func setupBackgroundProcess() {
        scheduler.setupBackgroundProcess()
    }
    
    func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .backgroundFetch, backgroundFetchCompletionHandler: backgroundFetchCompletion)
        eventPublisher.onNext(event)
    }
    
    func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .silentPushNotification, backgroundFetchCompletionHandler: backgroundFetchCompletion)
        eventPublisher.onNext(event)
    }
    
    func startBackgroundProcess(success: @escaping BoolClosure) {
        let event = SynchronizationTriggerEvent(source: .externalBackgroundProcess) { (result) in
            success(result != .failed)
        }
        eventPublisher.onNext(event)
    }
    
    func stopCurrentSynchronization() {
        scheduler.stopCurrentSynchronization()
    }
}
