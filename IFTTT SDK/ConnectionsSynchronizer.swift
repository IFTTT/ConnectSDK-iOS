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
        return strings.joined(separator: ", ")
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
    private let location: LocationService
    private let registry: ConnectionsRegistry
    private let connectionsMonitor: ConnectionsMonitor
    private let nativeServicesCoordinator: NativeServicesCoordinator
    private let subscribers: [SynchronizationSubscriber]
    private var scheduler: SynchronizationScheduler
    
    private var state: RunState = .unknown
    
    /// Private shared instance of connections synchronizer to use in starting/stopping synchronization
    private static var _shared: ConnectionsSynchronizer!
    
    /// Internal method to use in grabbing synchronizer instance.
    static func shared() -> ConnectionsSynchronizer {
        if _shared == nil {
            _shared = ConnectionsSynchronizer()
        }
        return _shared
    }
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    private init() {
        let regionEventsRegistry = RegionEventsRegistry()
        let connectionsRegistry = ConnectionsRegistry()
        let permissionsRequestor = PermissionsRequestor(registry: connectionsRegistry)
        let eventPublisher = EventPublisher<SynchronizationTriggerEvent>(queue: DispatchQueue.global())
        let regionsMonitor = RegionsMonitor(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled)
        let locationSessionManager = RegionEventsSessionManager(networkController: .init(),
                                                                regionEventsRegistry: regionEventsRegistry)
        
        let location = LocationService(regionsMonitor: regionsMonitor,
                                       regionEventsRegistry: regionEventsRegistry,
                                       connectionsRegistry: connectionsRegistry,
                                       sessionManager: locationSessionManager,
                                       eventPublisher: eventPublisher)
        
        let connectionsMonitor = ConnectionsMonitor(connectionsRegistry: connectionsRegistry)
        let nativeServicesCoordinator = NativeServicesCoordinator(locationService: location)

        self.subscribers = [
            connectionsMonitor,
            permissionsRequestor,
            location
        ]
        
        self.registry = connectionsRegistry
        self.nativeServicesCoordinator = nativeServicesCoordinator
        self.eventPublisher = eventPublisher
        self.location = location
        self.connectionsMonitor = connectionsMonitor
        
        let manager = SynchronizationManager(subscribers: subscribers)
        self.scheduler = SynchronizationScheduler(manager: manager,
                                             triggers: eventPublisher)
        
        setupRegistryNotifications()
        location.start()
    }
    
    /// Performs basic setup of the SDK with Application lifecycle synchronization options.
    ///
    /// - Parameters:
    ///     - lifecycleSynchronizationOptions: The synchronization options to use in setting up App Lifecycle notification observers.
    func setup(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        scheduler.setup(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
    }
    
    /// Can be used to force a synchronization.
    ///
    /// - Parameters:
    ///     - isActivation: Is this forced synchronization due to connections being activated?
    func update(isActivation: Bool = false) {
        let source: SynchronizationSource = isActivation ? .connectionActivation: .forceUpdate
        let event = SynchronizationTriggerEvent(source: source, backgroundFetchCompletionHandler: nil)
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
        update(isActivation: true)
    }
    
    /// Used to deactivate and stop synchronization.
    func deactivate() {
        ConnectButtonController.synchronizationLog("Deactivating synchronization...")
        stop()
        ConnectButtonController.synchronizationLog("Synchronization deactivated")
    }
    
    /// Call this to start the synchronization. Safe to be called multiple times.
    private func start() {
        if state == .running { return }
        
        setupNotifications()
        performPreflightChecks()
        Keychain.resetIfNecessary(force: false)
        scheduler.start()
        state = .running
    }
    
    /// Call this to stop the synchronization completely. Safe to be called multiple times.
    private func stop() {
        if state == .stopped { return }
        
        stopNotifications()
        Keychain.resetIfNecessary(force: true)
        scheduler.stop()
        state = .stopped
    }
    
    /// Runs checks to see what capabilities the target currently has and prints messages to the console as required.
    private func performPreflightChecks() {
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
    
    /// Stops notification observation
    private func stopNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupRegistryNotifications() {
        NotificationCenter.default.addObserver(forName: .UpdateConnectionsName,
                                               object: nil,
                                               queue: nil) { [weak self] (notification) in
            guard let userInfo = notification.userInfo,
                  let connectionUpdates = userInfo[ConnectionsRegistryNotification.UpdateConnectionsSetKey] as? [JSON] else { return }
            let connectionsSet = Set(connectionUpdates
                .compactMap { Connection.ConnectionStorage(json: $0) })
            self?.nativeServicesCoordinator.processConnectionUpdate(connectionsSet)
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

/// Handles coordination of native services with a set of connections
private class NativeServicesCoordinator {
    private let locationService: LocationService
    private let operationQueue: OperationQueue
    
    init(locationService: LocationService) {
        self.locationService = locationService
        self.operationQueue = OperationQueue.main
    }
    
    func processConnectionUpdate(_ updates: Set<Connection.ConnectionStorage>) {
        operationQueue.addOperation {
            self.locationService.updateRegions(from: updates)
        }
    }
}
