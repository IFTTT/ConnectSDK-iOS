//
//  SynchronizationManager.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import UIKit
import CoreLocation

/// A type responsible for performing a sync
final class SynchronizationManager {
    
    /// The subscribers that participate in the synchronization
    private let subscribers: [SynchronizationSubscriber]
    
    /// The sync currently being performed or nil if no sync is active
    private(set) var currentTask: Task?
    
    /// The next sync enqueued after the `currentTask`
    /// For many reasons we may schedule a sync directly following the one currently being performed
    /// For example, a location event will trigger a new sync
    /// We should blindly assume that this is always the right practice
    /// Perhaps this is a behavior would could question whenever working on improvements here
    private var nextTask: SynchronizationRequest?
    
    /// A type that encodes information about a sync to perform
    struct SynchronizationRequest {
        let source: SynchronizationSource
        let completion: ((UIBackgroundFetchResult, Bool) -> Void)?
    }
    
    /// Handles reachability state within the manager
    private let reachability = Reachability()
        
    /// Creates a `SyncManager`
    ///
    /// - Parameter subscribers: The `SyncSubscribers to perform during syncs
    init(subscribers: [SynchronizationSubscriber]) {
        self.subscribers = subscribers
    }
    
    /// Tells the `SyncManager` to perform a sync
    ///
    /// - Parameters:
    ///   - source: The `SynchronizationSource` that triggerered the synchronization.
    ///   - completion: Called when this sync completes. Returns the background fetch result and whether or not there was an authentication failure.
    func sync(source: SynchronizationSource,
              completion: ((UIBackgroundFetchResult, Bool) -> Void)?) {
        
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.sync(source: source, completion: completion)
            }
            return
        }
        
        if reachability?.connection == Reachability.Connection.none {
            // Generally it is bad practice to skip an API request because reachability fails
            // But since we are doing some operation in the background, let's just wait until we're sure the connection is active
            ConnectButtonController.synchronizationLog("Cancelling sync due to lack of network connectivity")
            completion?(.failed, false)
            return
        }
        
        if currentTask == nil {
            let activeSubscribers = subscribers.filter { $0.shouldParticipateInSynchronization(source: source) }
            let task = Task(source: source, subscribers: activeSubscribers)
            
            task.onComplete = { [weak self] result, authenticationFailure in
                if authenticationFailure {
                    ConnectButtonController.synchronizationLog("Synchronization interrupted due to authentication failure. Source: \(source)")
                } else {
                    ConnectButtonController.synchronizationLog("Completed synchronization. Source: \(source)")
                }
                
                self?.currentTask = nil
                completion?(result, authenticationFailure)
                
                if authenticationFailure {
                    self?.nextTask = nil
                } else if let nextTask = self?.nextTask {
                    self?.nextTask = nil
                    self?.sync(source: nextTask.source, completion: nextTask.completion)
                }
            }

            currentTask = task
            ConnectButtonController.synchronizationLog("Starting synchronization. Source: \(source)")
            task.start()
        } else {
            ConnectButtonController.synchronizationLog("Synchronization already in process. Setting up next synchronization to occur. Source: \(source)")
            nextTask = SynchronizationRequest(source: source, completion: completion)
        }
    }
    
    func start() {
        subscribers.forEach { $0.start() }
    }
    
    func reset() {
        subscribers.forEach { $0.reset() }
    }
}


// MARK: - Synchronization task

extension SynchronizationManager {
    class Task: NSObject {
        private(set) var identifier: UIBackgroundTaskIdentifier?
        
        let source: SynchronizationSource
        let createdAt = Date()
        
        private(set) var result: UIBackgroundFetchResult?
        private(set) var error: Error?
        
        let timeout: TimeInterval = 29.5
        
        override var description: String {
            return "source: \(source), createdAt: \(createdAt)"
        }
        
        func cancel() {
            finish()
        }
        
        private(set) var subscribers = [SynchronizationSubscriber]()
        
        private var resultsBySubscriber: [String : UIBackgroundFetchResult] = [:]
        
        fileprivate var onComplete: ((UIBackgroundFetchResult, Bool) -> Void)?
        
        fileprivate init(source: SynchronizationSource, subscribers: [SynchronizationSubscriber]) {
            self.source = source
            self.subscribers = subscribers
        }
        
        fileprivate func start() {
            guard subscribers.isEmpty == false else {
                onComplete?(.noData, false)
                return
            }
            
            if !source.isBackgroundProcess() {
                guard identifier == nil else {
                    return
                }
                
                identifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.finish()
                    }
                })
            }
            
            perform()
        }
        
        private func perform() {
            subscribers.forEach { (s) in
                s.performSynchronization { [weak self] (newData, error) in
                    self?.subscriber(s, didFinishWithNewData: newData, error: error)
                }
            }
        }
        
        private func subscriber(_ s: SynchronizationSubscriber, didFinishWithNewData newData: Bool, error: Error?) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async {
                    self.subscriber(s, didFinishWithNewData: newData, error: error)
                }
                return
            }
            
            let result: UIBackgroundFetchResult = error != nil ? .failed : (newData ? .newData : .noData)
            resultsBySubscriber[s.name] = result

            var finishEarly = false
            
            // If error == NetworkController.authenticationFailure then we finish early out of the task and let the manager of the task know about the authenticationFailure so it can escalate that up.
            // In this case, we'd also override `self.error` with NetworkController.authenticationFailure
            if let _error = error,
               let networkControllerError = _error as? NetworkControllerError,
               case .authenticationFailure = networkControllerError {
                self.error = error
                finishEarly = true
            } else if self.error == nil && error != nil {
                self.error = error
            }
            
            if resultsBySubscriber.count == subscribers.count || finishEarly {
                finish()
            }
        }
        
        private func finish() {
            guard self.result == nil else {
                onComplete?(.noData, false)
                if !source.isBackgroundProcess() {
                    if let identifier = identifier, identifier != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(identifier)
                    }
                }
                return
            }
            guard Thread.isMainThread else {
                DispatchQueue.main.async {
                    self.finish()
                }
                return
            }
            
            var result: UIBackgroundFetchResult = self.resultsBySubscriber.filter({ $0.value == .newData }).isEmpty ? .noData : .newData
            
            let authenticationFailure: Bool = {
                guard let _error = error,
                   let networkControllerError = _error as? NetworkControllerError,
                   case .authenticationFailure = networkControllerError else { return false }
                return true
            }()
            
            // If error == NetworkController.authenticationFailure then we let the manager of the task know about the authentication failure so it can escalate that up.
            if authenticationFailure {
                result = .failed
            } else if let _error = error {
                let error = _error as NSError
                if error.code != -1001 { // Timeout isn't an error because we use a degenerating timeout
                    result = .failed
                }
            }
            self.result = result
            
            onComplete?(result, authenticationFailure)
            
            if !source.isBackgroundProcess() {
                if let identifier = identifier, identifier != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
            }
        }
    }
}
