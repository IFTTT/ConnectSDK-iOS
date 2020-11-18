//
//  SynchronizationScheduler.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import BackgroundTasks
import UIKit

/// Schedules native integrations sync using `SynchronizationManager`
final class SynchronizationScheduler {
    /// Add this identifier to the Info.plist array for `BGTaskSchedulerPermittedIdentifiers`.
    static let BackgroundProcessIdentifier = "com.ifttt.ifttt.synchronization_scheduler"

    /// The `SynchronizationManager` to use when scheduling a sync
    private let manager: SynchronizationManager
    
    /// The token corresponding to the subscriber.
    private var subscriberToken: UUID?
    
    /// The lifecycle options to use in scheduling synchronizations
    private let lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions
    
    /// The tokens that get generated when the SDK sets up NotificationCenter observers
    private var notificationCenterTokens: [Any] = []
    
    /// Has the app opted into using background process?
    private var optedInToUsingSDKBackgroundProcess: Bool = false
    
    /// The triggers to kick off synchronizations
    private let triggers: EventPublisher<SynchronizationTriggerEvent>

    /// Creates a `SyncScheduler`
    ///
    /// - Parameters:
    ///   - syncManager: The `SyncManager` to use when scheduling a sync
    ///   - triggers: The publisher to use in publishing any possible events we might need to.
    ///   - lifecycleSynchronizationOptions: The options to use in scheduling app lifecycle events.
    init(manager: SynchronizationManager,
         triggers: EventPublisher<SynchronizationTriggerEvent>,
         lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        self.manager = manager
        self.triggers = triggers
        self.lifecycleSynchronizationOptions = lifecycleSynchronizationOptions
        setupSubscribers()
    }
    
    /// Performs registration for system and SDK generated events for kicking off synchronizations
    /// Should get called when the scheduler is to start. On iOS 13 and up, registers background process with the system.
    func start() {
        // Start the manager
        manager.start()
        
        // Start synchronization on system events
        var appLifecycleEventTuples = [(NSNotification.Name, SynchronizationSource, Bool)]()
        
        if lifecycleSynchronizationOptions.contains(.applicationDidBecomeActive) {
            appLifecycleEventTuples.append((UIApplication.didBecomeActiveNotification, .appDidBecomeActive, false))
        }
        if lifecycleSynchronizationOptions.contains(.applicationDidEnterBackground) {
            appLifecycleEventTuples.append((UIApplication.didEnterBackgroundNotification, .appBackgrounded, true))
        }
        
        let eventTuples: [(NSNotification.Name, SynchronizationSource, Bool)] = appLifecycleEventTuples + [
            (.ConnectionUpdatedNotification, .connectionsUpdate, true),
            (.ConnectionAddedNotification, .connectionAddition, true),
            (.ConnectionRemovedNotification, .connectionRemoval, true)
        ]
        
        self.notificationCenterTokens = eventTuples.map {
            return scheduleSynchronization(on: $0.0,
                                           source: $0.1,
                                           shouldRunInBackground: $0.2)
        }
    }
    
    /// Unregisters from system and SDK generated events for synchronizations.
    /// Should get called when the scheduler is to stop. On iOS 13 and up, un-registers from background processes with the system.
    func stop() {
        // Reset the manager
        manager.reset()
        
        // Unregister from background process
        // Remove observers from notification center
        notificationCenterTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        
        notificationCenterTokens = []
        
        // Cancel background tasks associated with the SDK
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: SynchronizationScheduler.BackgroundProcessIdentifier)
        }
        
        if let subscriberToken = subscriberToken {
            triggers.removeSubscriber(subscriberToken)
        }
        
        // Nil out the subscriber token
        subscriberToken = nil
    }
    
    /// Sets up subscriber with app generated triggers.
    private func setupSubscribers() {
        guard subscriberToken == nil else { return }
        
        self.subscriberToken = triggers.addSubscriber { [weak self] (triggerEvent) in
            guard let self = self else { return }
            self.manager.sync(source: triggerEvent.source,
                              completion: triggerEvent.backgroundFetchCompletionHandler)
        }
    }
    
    /// Helper method to schedule a synchronization with a `NSNotification`.
    ///
    /// - Parameters:
    ///     - notificationName: The name of the notification to register an observer for with the system.
    ///     - source: The `SynchronizationSource` that caused the synchronization to get started.
    ///     - shouldRunInBackground: A boolean flag that determines whether or not this synchronization should run in the background or not.
    private func scheduleSynchronization(on notificationName: Notification.Name,
                                         source: SynchronizationSource,
                                         shouldRunInBackground: Bool) -> Any {
        let body = { [weak self] (notification: Notification) in
            guard let self = self,
                UIApplication.shared.applicationState != .background || shouldRunInBackground else {
                    return
            }
            self.manager.sync(source: source, completion: nil)
        }
        return NotificationCenter.default.addObserver(forName: notificationName,
                                                      object: nil,
                                                      queue: .main,
                                                      using: body)
    }
    
    func stopCurrentSynchronization() {
        ConnectButtonController.synchronizationLog("Stopping current sync: \(String(describing: manager.currentTask))")
        manager.currentTask?.cancel()
    }
    
    func setupBackgroundProcess() {
        if #available(iOS 13.0, *) {
            guard Bundle.main.backgroundProcessingEnabled else { return }
            guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return }
            
            registerBackgroundProcess()
            optedInToUsingSDKBackgroundProcess = true
        }
    }
    
    /// Hook that should get called when the app enters the background. Schedules background process with the system.
    func applicationDidEnterBackground() {            
        if #available(iOS 13.0, *) {
            guard Bundle.main.backgroundProcessingEnabled else { return }
            guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return }
            guard optedInToUsingSDKBackgroundProcess else { return }
            
            scheduleBackgroundProcess()
        }
    }
    
    deinit {
        stop()
    }
}

@available(iOS 13.0, *)
extension SynchronizationScheduler {
    /// Schedules the background process for synchronizations with the system.
    private func scheduleBackgroundProcess() {
        let request = BGProcessingTaskRequest(identifier: SynchronizationScheduler.BackgroundProcessIdentifier)
        // We need network connectivity so that we can fetch the user's connections
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        // Try to run every hour
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 1)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error {
            ConnectButtonController.synchronizationLog("Error in scheduling background process: \(error)")
        }
    }

    /// Registers the background process to run with the system.
    private func registerBackgroundProcess() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: SynchronizationScheduler.BackgroundProcessIdentifier, using: nil) { [weak self] (task) in
            guard let appProcessTask = task as? BGProcessingTask else { return }

            self?.scheduleBackgroundProcess()
            self?.manager.sync(source: .internalBackgroundProcess) { (result) in
                let success = result != .failed
                if success != false {
                    ConnectButtonController.synchronizationLog("Synchronization resulted in a failed UIBackgroundFetch result")
                }
                appProcessTask.setTaskCompleted(success: success)
            }

             appProcessTask.expirationHandler = {
                ConnectButtonController.synchronizationLog("Synchronization took too long, expiration handler invoked")
                self?.manager.currentTask?.cancel()
            }
        }
    }
}
