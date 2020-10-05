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

public func debugPrint(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}

/// Controls current running state
enum RunState {
    /// Currently stopped
    case stopped
    
    /// Currently running
    case running
}

public typealias BoolClosure = (Bool) -> Void

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
    private let connectionsMonitor: ConnectionsMonitor
    private let subscribers: [SynchronizationSubscriber]
    private var state: RunState = .stopped
    
    /// Shared instance of connections synchronizer to use in starting/stopping synchronization
    public static let shared = ConnectionsSynchronizer()
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    private init() {
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
        self.eventPublisher = eventPublisher
        self.scheduler = SynchronizationScheduler(manager: manager, triggers: eventPublisher)
        self.location = location
        self.connectionsMonitor = connectionsMonitor
    }
    
    /// Can be used to force a synchronization.
    func update() {
        let event = SynchronizationTriggerEvent(source: .forceUpdate, backgroundFetchCompletionHandler: nil)
        eventPublisher.onNext(event)
    }
    
    /// Call this to start the synchronization. This should be called preferably as early as possible and after the app determines that the user is logged in. Safe to be called multiple times.
    func start() {
        guard state == .stopped else { return }
        
        setupNotifications()
        performPreflightChecks()
        Keychain.resetIfNecessary(force: false)
        scheduler.start()
        state = .running
    }
    
    /// Call this to stop the synchronization. This should be called when the user is logged out. Safe to be called multiple times.
    func stop() {
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
            debugPrint("Background processing not enabled for this target! Enable background processing to allow Connections to get synchronized more frequently.")
        } else if Bundle.main.backgroundProcessingEnabled && !Bundle.main.containsIFTTTBackgroundProcessingIdentifier {
            debugPrint("Missing IFTTT background processing task identifier. Add com.ifttt.ifttt.synchronization_scheduler to the BGTaskSchedulerPermittedIdentifiers array of the info plist for this target.")
        }
        
        if !Bundle.main.backgroundLocationEnabled {
            debugPrint("Background location not enabled for this target! Enable background location to allow location updates to be delivered to the app in the background.")
        }
    }
    
    /// Peforms internal setup to allow the SDK to perform work in response to notification center notifications.
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    /// Hook to be called when the application enters the background.
    @objc private func applicationDidEnterBackground() {
        if #available(iOS 13.0, *) {
            scheduler.applicationDidEnterBackground()
        }
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
