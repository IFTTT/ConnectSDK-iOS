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

/**
 Handles synchronizing events from the SDK to the backend.
 
 Uses the following mechanisms to do so:
 - Background processing
 - App lifecycle events
    - App going to background
    - App transitions to active state
 - Other events specified by `SynchronizationSource`
*/
public final class ConnectionsSynchronizer {
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
    public func update() {
        let event = SynchronizationTriggerEvent(source: .forceUpdate, backgroundFetchCompletionHandler: nil)
        eventPublisher.onNext(event)
    }
    
    /// Call this to start the synchronization. This should be called preferably as early as possible and after the app determines that the user is logged in. Safe to be called multiple times.
    public func start() {
        guard state == .stopped else { return }
        
        setupNotifications()
        let useBackgroundFetch = false
        performPreflightChecks(useBackgroundFetch: useBackgroundFetch)
        resetKeychainIfNecessary()
        if #available(iOS 13.0, *) {
            scheduler.start()
        } else {
            guard Bundle.main.backgroundFetchEnabled, useBackgroundFetch else { return }
            // We must set the interval to setMinimumBackgroundFetchInterval(...) to a value to something other than the default of UIApplication.backgroundFetchIntervalNever
            let closure : () -> Void  = { UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            }
            closure()
        }
        state = .running
    }
    
    /// Call this to stop the synchronization. This should be called when the user is logged out. Safe to be called multiple times.
    public func stop() {
        guard state == .running else { return }
        
        Keychain.reset()
        scheduler.stop()
        NotificationCenter.default.removeObserver(self)
        subscribers.forEach { $0.reset() }
        state = .stopped
    }
    
    /// Runs checks to see what capabilities the target currently has and prints messages to the console as required.
    private func performPreflightChecks(useBackgroundFetch: Bool) {
        if !Bundle.main.backgroundFetchEnabled && useBackgroundFetch {
            debugPrint("Background fetch not enabled for this target! Enable background fetch to allow Connections to get synchrnonized more frequently.")
        }
        
        if !Bundle.main.backgroundProcessingEnabled {
            debugPrint("Background processing not enabled for this target! Enable background processing to allow Connections to get synchrnonized more frequently.")
        } else if Bundle.main.backgroundProcessingEnabled && !Bundle.main.containsIFTTTBackgroundProcessingIdentifier {
            debugPrint("Missing IFTTT background processing task identifier. Add com.ifttt.ifttt.synchronization_scheduler to the BGTaskSchedulerPermittedIdentifiers array of the info plist for this target.")
        }
        
        if !Bundle.main.backgroundLocationEnabled {
            debugPrint("Background location not enabled for this target! Enable background location to allow location updates to be delivered to the app in the background.")
        }
    }
    
    /// Resets the keychain if the user defaults is missing SDK-related data. This typically happens when the app is deleted and re-installed.
    private func resetKeychainIfNecessary() {
        if UserDefaults.anonymousId == nil {
            Keychain.reset()
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
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `setMinimumBackgroundFetchInterval` method call.
    public func performFetchWithCompletionHandler(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .backgroundFetch, backgroundFetchCompletionHandler: backgroundFetchCompletion)
        eventPublisher.onNext(event)
    }
    
    /// Hook to be called when the `UIApplicationDelegate` recieves the `application:didReceiveRemoteNotification:` method call. This method should only be called when your app recieves a silent push notification.
    public func didReceiveSilentRemoteNotification(backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?) {
        let event = SynchronizationTriggerEvent(source: .silentPushNotification, backgroundFetchCompletionHandler: backgroundFetchCompletion)
        eventPublisher.onNext(event)
    }
}
