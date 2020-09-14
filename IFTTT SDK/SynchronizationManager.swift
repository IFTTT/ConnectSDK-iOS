//
//  SynchronizationManager.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// A type responsible for performing a sync
final class SynchronizationManager {
    
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
        let completion: ((UIBackgroundFetchResult) -> Void)?
    }
    
    private let reachability = Reachability()
        
    /// Creates a `SyncManager`
    ///
    /// - Parameter subscribers: The `SyncSubscribers to perform during syncs
    init(subscribers: Array<SynchronizationSubscriber>) {
        self.subscribers = subscribers
    }
    
    /// Tells the `SyncManager` to perform a sync
    ///
    /// - Parameters:
    ///   - source: The `SynchronizationSource` that triggerered the synchronization.
    ///   - notificationContent: The contents of the notification that triggered this sync or an empty value
    ///   - syncConfiguration: The current configuration for syncs (as defined by the user in settings)
    ///   - completion: Called when this sync completes. Returns the background fetch result.
    func sync(source: SynchronizationSource,
              completion: ((UIBackgroundFetchResult) -> Void)?) {
        
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.sync(source: source, completion: completion)
            }
            return
        }
        
        if reachability?.connection == Reachability.Connection.none {
            // Generally it is bad practice to skip an API request because reachability fails
            // But since we are doing some operation in the background, let's just wait until we're sure the connection is active
            completion?(.failed)
            return
        }
        
        if currentTask == nil {
            let activeSubscribers = subscribers.filter { $0.shouldParticipateInSynchronization(source: source) }
            let task = Task(source: source, subscribers: activeSubscribers)
            
            task.onComplete = { [weak self] result in
                self?.currentTask = nil
                completion?(result)
                
                if let nextTask = self?.nextTask {
                    self?.nextTask = nil
                    self?.sync(source: nextTask.source, completion: nextTask.completion)
                }
            }
            currentTask = task
            task.start()
        } else {
            nextTask = SynchronizationRequest(source: source, completion: completion)
        }
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
        
        func cancel() {
            finish()
        }
        
        private(set) var subscribers: Array<SynchronizationSubscriber> = []
        
        private var resultsBySubscriber: [String : UIBackgroundFetchResult] = [:]
        
        fileprivate var onComplete: ((UIBackgroundFetchResult) -> Void)?
        
        fileprivate init(source: SynchronizationSource, subscribers: [SynchronizationSubscriber]) {
            self.source = source
            self.subscribers = subscribers
        }
        
        fileprivate func start() {
            guard subscribers.isEmpty == false else {
                onComplete?(.noData)
                return
            }
            
            if source != .backgroundProcess {
                guard identifier == nil else {
                    return
                }
            }
            
            if source != .backgroundProcess {
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

            if self.error == nil && error != nil { // Record the first error
                self.error = error
            }
            if resultsBySubscriber.count == subscribers.count {
                finish()
            }
        }
        
        private func finish() {
            guard self.result == nil else {
                onComplete?(.noData)
                if source != .backgroundProcess {
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
            
            if let _error = error {
                let error = _error as NSError
                if error.code != -1001 { // Timeout isn't an error because we use a degenerating timeout
                    result = .failed
                }
            }
            self.result = result
            
            onComplete?(result)
            
            if source != .backgroundProcess {
                if let identifier = identifier, identifier != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(identifier)
                }
            }
        }
    }
}
