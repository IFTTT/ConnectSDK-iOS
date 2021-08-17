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
    private let permissionsRequestor: PermissionsRequestor
    
    private var state: RunState = .unknown
    
    /// Private shared instance of connections synchronizer to use in starting/stopping synchronization
    private static var _shared: ConnectionsSynchronizer!
    
    /// Internal method to use in grabbing synchronizer instance.
    static var shared: ConnectionsSynchronizer = {
        if _shared == nil {
            _shared = ConnectionsSynchronizer()
        }
        return _shared
    }()
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    private init() {
        let regionEventsRegistry = RegionEventsRegistry()
        let connectionsRegistry = ConnectionsRegistry()
        let permissionsRequestor = PermissionsRequestor(registry: connectionsRegistry)
        let eventPublisher = EventPublisher<SynchronizationTriggerEvent>()
        let regionsMonitor = RegionsMonitor(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled)
        let locationSessionManager = RegionEventsSessionManager(networkController: .init(urlSession: .regionEventsURLSession),
                                                                regionEventsRegistry: regionEventsRegistry)
        
        let location = LocationService(regionsMonitor: regionsMonitor,
                                       regionEventsRegistry: regionEventsRegistry,
                                       connectionsRegistry: connectionsRegistry,
                                       sessionManager: locationSessionManager,
                                       eventPublisher: eventPublisher)
        
        let connectionsMonitor = ConnectionsMonitor(connectionsRegistry: connectionsRegistry)
        let nativeServicesCoordinator = NativeServicesCoordinator(locationService: location,
                                                                  permissionsRequestor: permissionsRequestor)

        self.subscribers = [
            connectionsMonitor,
            location
        ]
        
        self.registry = connectionsRegistry
        self.nativeServicesCoordinator = nativeServicesCoordinator
        self.eventPublisher = eventPublisher
        self.location = location
        self.connectionsMonitor = connectionsMonitor
        self.permissionsRequestor = permissionsRequestor
        
        let manager = SynchronizationManager(subscribers: subscribers)
        self.scheduler = SynchronizationScheduler(manager: manager,
                                                  triggers: eventPublisher)
        self.scheduler.onAuthenticationFailure = { [weak self] in
            self?.deactivate()
            ConnectButtonController.authenticationFailureHandler?()
        }
        setupRegistryNotifications()
        location.start()
    }
    
    /// Can be used to force a synchronization.
    ///
    /// - Parameters:
    ///     - isActivation: Is this forced synchronization due to connections being activated?
    func update(isActivation: Bool = false) {
        let source: SynchronizationSource = isActivation ? .connectionActivation: .forceUpdate
        let event = SynchronizationTriggerEvent(source: source, completionHandler: nil)
        eventPublisher.onNext(event)
    }
    
    /// Used to start the synchronization.
    ///
    /// - Parameters:
    ///     - connections: An optional list of connections to start monitoring.
    ///     - lifecycleSynchronizationOptions: The app lifecycle synchronization options to use with the scheduler
    func activate(connections ids: [String]? = nil, lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        if let ids = ids {
            registry.addConnections(with: ids, shouldNotify: false)
            ConnectButtonController.synchronizationLog("Activated synchronization with connection ids: \(ids)")
        } else {
            ConnectButtonController.synchronizationLog("Activated synchronization")
        }
        start(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
        update(isActivation: true)
    }
    
    /// Used to deactivate and stop synchronization.
    func deactivate() {
        ConnectButtonController.synchronizationLog("Deactivating synchronization...")
        stop()
        ConnectButtonController.synchronizationLog("Synchronization deactivated")
    }
    
    /// Call this to start the synchronization. Safe to be called multiple times.
    private func start(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        if state == .running { return }
        
        performPreflightChecks()
        Keychain.resetIfNecessary(force: false)
        scheduler.start(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
        state = .running
    }
    
    /// Call this to stop the synchronization completely. Safe to be called multiple times.
    private func stop() {
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
    
    /// Call this to tear down background processes.
    func teardownBackgroundProcess() {
        scheduler.tearDownBackgroundProcess()
    }
    
    /// Call this to control whether or not the SDK should show permissions prompts.
    func setShowPermissionsPrompts(_ showPermissionsPrompts: Bool) {
        permissionsRequestor.showPermissionsPrompts = showPermissionsPrompts
    }
    
    func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .backgroundFetch) { (result, _) in
            backgroundFetchCompletion?(result)
        }
        eventPublisher.onNext(event)
    }
    
    func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .silentPushNotification) { (result, _) in
            backgroundFetchCompletion?(result)
        }
        eventPublisher.onNext(event)
    }
    
    func startBackgroundProcess(success: @escaping BoolClosure) {
        let event = SynchronizationTriggerEvent(source: .externalBackgroundProcess) { (result, _) in
            success(result != .failed)
        }
        eventPublisher.onNext(event)
    }
    
    func stopCurrentSynchronization() {
        scheduler.stopCurrentSynchronization()
    }
    
    func setGeofencesEnabled(_ enabled: Bool, for connectionId: String) {
        registry.updateConnectionGeofencesEnabled(enabled, connectionId: connectionId)
    }
    
    func geofencesEnabled(for connectionId: String) -> Bool {
        return registry.geofencesEnabled(connectionId: connectionId)
    }
    
    func setDeveloperBackgroundProcessClosures(launchHandler: VoidClosure?, expirationHandler: VoidClosure?) {
        scheduler.developerBackgroundProcessLaunchClosure = launchHandler
        scheduler.developerBackgroundProcessExpirationClosure = expirationHandler
    }
}

/// Handles coordination of native services with a set of connections
private class NativeServicesCoordinator {
    private let locationService: LocationService
    private let permissionsRequestor: PermissionsRequestor
    
    init(locationService: LocationService, permissionsRequestor: PermissionsRequestor) {
        self.locationService = locationService
        self.permissionsRequestor = permissionsRequestor
    }
    
    func processConnectionUpdate(_ updates: Set<Connection.ConnectionStorage>) {
        permissionsRequestor.processUpdate(with: updates)
        locationService.updateRegions(from: updates)
    }
}
