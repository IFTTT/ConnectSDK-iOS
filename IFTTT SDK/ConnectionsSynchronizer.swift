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

/**
 Handles synchronizing events from the SDK to the backend.
 
 Uses the following mechanisms to do so:
 - Silent remote push notifications
 - Background fetch
 - Background processing
*/
public final class ConnectionsSynchronizer {
    private let eventPublisher: EventPublisher<SynchronizationTriggerEvent>
    private let scheduler: SynchronizationScheduler
    private let location: LocationService
    private let connectionsMonitor: ConnectionsMonitor
    
    /// An `ConnectButtonControllerDelegate` object that will recieved messages about events that happen on the `ConnectButtonController`.
     public private(set) weak var delegate: ConnectButtonControllerDelegate?
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    public init() {
        let regionEventsRegistry = RegionEventsRegistry()
        let connectionsRegistry = ConnectionsRegistry()
        let permissionsRequestor = PermissionsRequestor(registry: connectionsRegistry)
        let eventPublisher = EventPublisher<SynchronizationTriggerEvent>(queue: DispatchQueue.global())

        let location = LocationService(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled,
                                       regionEventsRegistry: regionEventsRegistry,
                                       connectionsRegistry: connectionsRegistry,
                                       eventPublisher: eventPublisher)
        
        let connectionsMonitor = ConnectionsMonitor(connectionsRegistry: connectionsRegistry)
        
        let subscribers: [SynchronizationSubscriber] = [
            connectionsMonitor,
            permissionsRequestor,
            location
        ]
        
        let manager = SynchronizationManager(subscribers: subscribers)
        self.eventPublisher = eventPublisher
        self.scheduler = SynchronizationScheduler(manager: manager, triggers: eventPublisher)
        self.location = location
        self.connectionsMonitor = connectionsMonitor
        
        setupNotifications()
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
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinishLaunchingWithOptions),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    /// Hook to be called when the application finishes launching. This performs pre-flight checks along with setting up background fetch or background processing and starting the synchronization scheduler.
    @objc private func didFinishLaunchingWithOptions() {
        let useBackgroundFetch = false
        performPreflightChecks(useBackgroundFetch: useBackgroundFetch)
        resetKeychainIfNecessary()
        if #available(iOS 13.0, *) {
            scheduler.didFinishLaunchingWithOptions()
        } else {
            guard Bundle.main.backgroundFetchEnabled, useBackgroundFetch else { return }
            // We must set the interval to setMinimumBackgroundFetchInterval(...) to a value to something other than the default of UIApplication.backgroundFetchIntervalNever
            let closure : () -> Void  = { UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            }
            closure()
        }
        
        scheduler.start()
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
