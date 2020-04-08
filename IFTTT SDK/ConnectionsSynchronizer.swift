//
//  ConnectionsSynchronizer.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

/**
 Handles synchronizing events from the SDK to the backend.
 
 Uses the following mechanisms to do so:
 - Silent remote push notifications
 - Background fetch
 - Background processing
*/
public final class ConnectionsSynchronizer {
    /// The shared instance to use in calling designated hooks to run synchronizations as required.
    public static let shared = ConnectionsSynchronizer()
    
    private let eventPublisher: EventPublisher<SynchronizationTriggerEvent>
    private let scheduler: SynchronizationScheduler
    private let location: LocationService
    private let connectionsMonitor: ConnectionsMonitor
    
    /// Creates an instance of the `ConnectionsSynchronizer`.
    private init() {
        let location = LocationService(allowsBackgroundLocationUpdates: Bundle.main.backgroundLocationEnabled)
        let connectionsMonitor = ConnectionsMonitor(location: location)
        
        let subscribers: [SynchronizationSubscriber] = [
            connectionsMonitor
        ]
        
        let manager = SynchronizationManager(subscribers: subscribers)
        let eventPublisher = EventPublisher<SynchronizationTriggerEvent>(queue: DispatchQueue.global())
        self.eventPublisher = eventPublisher
        self.scheduler = SynchronizationScheduler(manager: manager, triggers: eventPublisher)
        self.location = location
        self.connectionsMonitor = connectionsMonitor
    }
    
    /// Runs checks to see what capabilities the target currently has and prints messages to the console as required.
    private func performPreflightChecks() {
        if !Bundle.main.backgroundFetchEnabled {
            print("Background fetch not enabled for this target! Enable background fetch to allow Connections to get synchrnonized more frequently.")
        }
        
        if !Bundle.main.backgroundProcessingEnabled {
            print("Background processing not enabled for this target! Enable background processing to allow Connections to get synchrnonized more frequently.")
        } else if Bundle.main.backgroundProcessingEnabled && !Bundle.main.containsIFTTTBackgroundProcessingIdentifier {
            print("Missing IFTTT background processing task identifier. Add com.ifttt.ifttt.synchronization_scheduler to the BGTaskSchedulerPermittedIdentifiers array of the info plist for this target.")
        }
        
        if !Bundle.main.backgroundLocationEnabled {
            print("Background location not enabled for this target! Enable background location to allow location updates to be delivered to the app in the background.")
        }
    }
    
    /// Hook to be called when the application finishes launching. This performs pre-flight checks along with setting up background fetch or background processing and starting the synchronization scheduler.
    public func applicationDidFinishLaunching() {
        performPreflightChecks()
        if #available(iOS 13.0, *) {
            scheduler.applicationDidFinishLaunching()
        } else {
            guard Bundle.main.backgroundFetchEnabled else { return }
            // We must set the interval to setMinimumBackgroundFetchInterval(...) to a value to something other than the default of UIApplication.backgroundFetchIntervalNever
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        
        scheduler.start()
    }

    /// Hook to be called when the application enters the background.
    public func applicationDidEnterBackground() {
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
