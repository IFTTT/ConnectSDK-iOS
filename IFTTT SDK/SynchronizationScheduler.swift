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
    private(set) var subscriberToken: UUID?
    
    /// The tokens that get generated when the SDK sets up application lifecycle NotificationCenter observers
    private(set) var applicationLifecycleNotificationCenterTokens: [Any] = []
    
    /// The tokens that get generated when the SDK sets up other NotificationCenter observers
    private(set) var sdkGeneratedNotificationCenterTokens: [Any] = []
    
    /// Has the app opted into using background process?
    private(set) var optedInToUsingSDKBackgroundProcess: Bool = false
    
    /// The triggers to kick off synchronizations
    private let triggers: EventPublisher<SynchronizationTriggerEvent>
    
    /// A closure that gets invoked after an authentication failure in a sync task
    var onAuthenticationFailure: VoidClosure?

    /// A `DispatchQueue` to use in executing `developerBackgroundProcessClosure`.
    private let developerBackgroundProcessDispatchQueue = DispatchQueue(label: "com.ifttt.backgroundprocess.developer_closure")
    
    /// A closure that's passed in by the developer to execute when a background process handler gets called.
    var developerBackgroundProcessLaunchClosure: VoidClosure?
    
    /// A closure that's called when expiration of the background process occurs. This is supplied by the developer.
    var developerBackgroundProcessExpirationClosure: VoidClosure?

    /// Creates a `SyncScheduler`
    ///
    /// - Parameters:
    ///   - syncManager: The `SyncManager` to use when scheduling a sync
    ///   - triggers: The publisher to use in publishing any possible events we might need to.
    init(manager: SynchronizationManager, triggers: EventPublisher<SynchronizationTriggerEvent>) {
        self.manager = manager
        self.triggers = triggers
        startAppSubscribers()
    }
    
    /// Performs registration for system and SDK generated events for kicking off synchronizations
    /// Should get called when the scheduler is to start.
    func start(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        // Remove any previous tokens that might still be around
        removeSDKGeneratedNotificationObservers()
        removeLifecycleNotificationObservers()
        removeAppSubscribers()
        
        // Start the manager
        manager.start()
        
        // Start SDK generated subscribers
        startSDKGeneratedSubscribers()
        // Start app lifecycle subscribers
        startApplicationLifecycleSubscribers(lifecycleSynchronizationOptions: lifecycleSynchronizationOptions)
        // Start app generated subscribers()
        startAppSubscribers()
    }
    
    /// Unregisters from system and SDK generated events for synchronizations.
    /// Should get called when the scheduler is to stop. On iOS 13 and up, un-registers from background processes with the system.
    func stop() {
        // Reset the manager
        manager.reset()
        
        // Remove observers from notification center
        removeLifecycleNotificationObservers()
        removeSDKGeneratedNotificationObservers()
        removeAppSubscribers()
        
        // Cancel background tasks associated with the SDK
        cancelBackgroundProcess()
    }
    
    private func removeLifecycleNotificationObservers() {
        applicationLifecycleNotificationCenterTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        applicationLifecycleNotificationCenterTokens = []
    }
    
    private func removeSDKGeneratedNotificationObservers() {
        sdkGeneratedNotificationCenterTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        sdkGeneratedNotificationCenterTokens = []
    }
    
    private func removeAppSubscribers() {
        if let subscriberToken = subscriberToken {
            triggers.removeSubscriber(subscriberToken)
        }
        
        // Nil out the subscriber token
        subscriberToken = nil
    }
    
    /// Sets up subscribers with app lifecycle events
    private func startApplicationLifecycleSubscribers(lifecycleSynchronizationOptions: ApplicationLifecycleSynchronizationOptions) {
        // Start synchronization on system events
        var appLifecycleEventTuples = [(NSNotification.Name, SynchronizationSource, Bool)]()
        
        if lifecycleSynchronizationOptions.contains(.applicationDidBecomeActive) {
            appLifecycleEventTuples.append((UIApplication.didBecomeActiveNotification, .appDidBecomeActive, false))
        }
        if lifecycleSynchronizationOptions.contains(.applicationDidEnterBackground) {
            appLifecycleEventTuples.append((UIApplication.didEnterBackgroundNotification, .appBackgrounded, true))
        }
        
        var tokens = appLifecycleEventTuples.map {
            return scheduleSynchronization(on: $0.0,
                                           source: $0.1,
                                           shouldRunInBackground: $0.2)
        }
        
        if #available(iOS 13.0, *) {
            let token = NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: nil)
            { [weak self] _ in
                self?.applicationDidEnterBackground()
            }
            tokens.append(token)
        }
        
        self.applicationLifecycleNotificationCenterTokens = tokens
    }
    
    /// Starts subscribers with app generated triggers.
    private func startAppSubscribers() {
        guard subscriberToken == nil else { return }
        
        self.subscriberToken = triggers.addSubscriber { [weak self] (triggerEvent) in
            guard let self = self else { return }
            self.manager.sync(source: triggerEvent.source) { (result, authenticationFailure) in
                if authenticationFailure {
                    self.onAuthenticationFailure?()
                }
                triggerEvent.completionHandler?(result, authenticationFailure)
            }
        }
    }
    
    /// Starts subscribers with SDK generated triggers.
    private func startSDKGeneratedSubscribers() {
        // Start monitoring the notifications related to Connection CRUD operations
        let eventTuples: [(NSNotification.Name, SynchronizationSource, Bool)] = [
            (.ConnectionUpdatedNotification, .connectionsUpdate, true),
            (.ConnectionAddedNotification, .connectionAddition, true)
        ]
        
        self.sdkGeneratedNotificationCenterTokens = eventTuples.map {
            return scheduleSynchronization(on: $0.0,
                                           source: $0.1,
                                           shouldRunInBackground: $0.2)
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
            self.manager.sync(source: source) { [weak self] _, authenticationFailure in
                if authenticationFailure {
                    self?.onAuthenticationFailure?()
                }
            }
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
    
    private func canUseBackgroundProcesses() -> Bool {
        guard Bundle.main.backgroundProcessingEnabled else { return false }
        guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return false }
        
        return true
    }
    
    private func cancelBackgroundProcess() {
        // Cancel background tasks associated with the SDK
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: SynchronizationScheduler.BackgroundProcessIdentifier)
        }
    }
    
    func setupBackgroundProcess() {
        if #available(iOS 13.0, *) {
            guard canUseBackgroundProcesses() else { return }
            
            registerBackgroundProcess()
            optedInToUsingSDKBackgroundProcess = true
        }
    }
    
    func tearDownBackgroundProcess() {
        if #available(iOS 13.0, *) {
            guard Bundle.main.backgroundProcessingEnabled else { return }
            guard Bundle.main.containsIFTTTBackgroundProcessingIdentifier else { return }
            
            cancelBackgroundProcess()
            optedInToUsingSDKBackgroundProcess = false
        }
    }
    
    /// Hook that should get called when the app enters the background. Schedules background process with the system.
    @objc func applicationDidEnterBackground() {
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
        let credentialProvider = UserAuthenticatedRequestCredentialProvider.standard
        let isLoggedIn = credentialProvider.userToken != nil
        
        if !isLoggedIn {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: SynchronizationScheduler.BackgroundProcessIdentifier)
            return
        }
        
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
            appProcessTask.expirationHandler = {
                self?.developerBackgroundProcessDispatchQueue.async {
                    self?.developerBackgroundProcessExpirationClosure?()
                }
                
                ConnectButtonController.synchronizationLog("Synchronization took too long, expiration handler invoked")
                self?.manager.currentTask?.cancel()
                appProcessTask.setTaskCompleted(success: true)
            }
            
            self?.developerBackgroundProcessDispatchQueue.async {
                self?.developerBackgroundProcessLaunchClosure?()
            }
            
            self?.manager.sync(source: .internalBackgroundProcess) { (result, authenticationFailure) in
                let success = result != .failed
                if !success {
                    ConnectButtonController.synchronizationLog("Synchronization resulted in a failed UIBackgroundFetch result")
                }
                if authenticationFailure {
                    self?.onAuthenticationFailure?()
                }
                appProcessTask.setTaskCompleted(success: success)
            }
        }
    }
}
