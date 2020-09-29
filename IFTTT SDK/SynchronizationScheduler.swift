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
    
    private var notificationCenterTokens: [Any] = []
    
    /// The triggers to kick off synchronizations
    private let triggers: EventPublisher<SynchronizationTriggerEvent>

    /// Creates a `SyncScheduler`
    ///
    /// - Parameters:
    ///   - syncManager: The `SyncManager` to use when scheduling a sync
    ///   - triggers: The publisher to use in publishing any possible events we might need to.
    init(manager: SynchronizationManager, triggers: EventPublisher<SynchronizationTriggerEvent>) {
        self.manager = manager
        self.triggers = triggers
    }
    
    /// Performs registration for system and SDK generated events for kicking off synchronizations
    /// Should get called when the scheduler is to start. Registers background process with the system.
    func start() {
        // Start synchronization on system events
        let eventTuples: [(NSNotification.Name, SynchronizationSource, Bool)] = [
            (UIApplication.didBecomeActiveNotification, .appDidBecomeActive, false),
            (UIApplication.didEnterBackgroundNotification, .appBackgrounded, true),
            (.ConnectionUpdatedNotification, .connectionsUpdate, true),
            (.ConnectionAddedNotification, .connectionAddition, true),
            (.ConnectionRemovedNotification, .connectionRemoval, true)
        ]
        
        self.notificationCenterTokens = eventTuples.map {
            return scheduleSynchronization(on: $0.0,
                                           source: $0.1,
                                           shouldRunInBackground: $0.2)
        }
        
        self.subscriberToken = triggers.addSubscriber { [weak self] (triggerEvent) in
            guard let self = self else { return }
            self.manager.sync(source: triggerEvent.source,
                              completion: triggerEvent.backgroundFetchCompletionHandler)
        }
        
        if #available(iOS 13.0, *) {
            guard Bundle.main.backgroundProcessingEnabled else { return }
            guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return }
            
            registerBackgroundProcess()
        }
    }
    
    func stop() {
        // Unregister from background process
        // Remove observers from notification center
        notificationCenterTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        notificationCenterTokens = []
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancelAllTaskRequests()
        } else { }
        
        if let subscriberToken = subscriberToken {
            triggers.removeSubscriber(subscriberToken)
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
    
    /// Hook that should get called when the app enters the background. Schedules background process with the system.
    func applicationDidEnterBackground() {            
        if #available(iOS 13.0, *) {
            guard Bundle.main.backgroundProcessingEnabled else { return }
            guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return }
            
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
        } catch {
            // TODO: Log error here
        }
    }

    /// Registers the background process to run with the system.
    private func registerBackgroundProcess() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: SynchronizationScheduler.BackgroundProcessIdentifier, using: nil) { [weak self] (task) in
            guard let appProcessTask = task as? BGProcessingTask else { return }

            self?.scheduleBackgroundProcess()
            self?.manager.sync(source: .backgroundProcess) { (result) in
                let success = result != .failed
                // TODO: Log error here if result == .failed
                appProcessTask.setTaskCompleted(success: success)
            }

             appProcessTask.expirationHandler = {
                // TODO: Log expiration handler getting called here
                self?.manager.currentTask?.cancel()
            }
        }
    }
}
