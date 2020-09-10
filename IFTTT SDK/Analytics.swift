//
//  Analytics.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

private extension Date {
    /// Returns the number of milliseconds between `self` and 00:00:00 UTC on 1 January 1970. Rounded to remove any trailing decimals.
    var roundedMillisecondsSince1970: String {
        return "\(Int64((timeIntervalSince1970 * 1000).rounded()))"
    }
}

/// Handles sending analytics events for the SDK.
final class Analytics {
    // MARK: - Configurable
    /// Boolean value that enables or disables analytics collection. By default, this value is set to `true`.
    var enabled: Bool = true {
        didSet {
            if !enabled {
                stop()
            } else {
                start()
            }
        }
    }
    
    /// `Analytics` shared instance object.
    static var shared = Analytics()

    /// A boolean variable that tracks whether or not analytics has been started or not
    private var hasBeenStarted = false
    
    /// Determines whether or not Analytics logging should be printed to console or not.
    private static var loggingEnabled: Bool = false
    
    private struct Constants {
        /// The label of the dispatch queue used to handle queuing, uploading, and batching of events in the foreground.
        static let ForegroundQueueLabel = "ifttt_sdk.analytics.io"
        
        /// The label of the dispatch queue used to handle events utilizing `UIApplication`'s background tasks.
        static let BackgroundQueueLabel = "ifttt_sdk.analytics.backgroundTask"

        /// The key used to identify the background task (if one is started) for any Analytics events.
        static let BackgroundTaskIdentifier = "ifttt_sdk.analytics.io.flush"
        
        /// Value that determines how many events to force flush. If the queue if forcibly flushed, then the first `ForceFlushCount` events are flushed.
        static let ForceFlushCount = 10
        
        /// Value that determines the maximum size the queue can get to. If the queue size grows bigger than this, the oldest event in the queue gets dropped.
        static let QueueDropSize = 100
        
        /// A value in seconds that controls how often a flush of any queued analytics events should occur. By default, this value is set to 30 seconds.
        static let flushTimerTimeout: TimeInterval = 30.0
        
        /// Controls how large the queue size should get before a flush occurs. By default, this value is set to 5.
        static let flushCount: Int = 5
    }
    
    /// Creates an instance of `Analytics`
    ///
    /// - Returns: An initialized instance of `Analytics`.
    private init() {
        // Check for previous queue/track data in NSUserDefaults and remove if present
        run { [weak self] in
            self?.deleteQueue()
        }
        start()
    }
    
    // MARK: - Logging
    /// Logs analytics events to the console only if `loggingEnabled` is `true`.
    ///
    /// - Parameters:
    ///     - event: A string corresponding to the event.
    private static func log(_ event: String) {
        guard loggingEnabled else { return }
        print("ANALYTICS: \(event)")
    }
    
    /// The `AnalyticsNetworkController` used in uploading Analytics events.
    private let networkController = AnalyticsNetworkController()
    
    /// The `DispatchQueue` that's used to handle queuing and batch uploading of events.
    private let foregroundQueue = DispatchQueue(label: Constants.ForegroundQueueLabel)
    
    /// The `DispatchQueue` that's used to handle any work needed to be done while the app is in the background.
    private let backgroundQueue = DispatchQueue(label: Constants.BackgroundQueueLabel)
    
    /// A reference to the current request in flight for any uploaded events. For simplicity, we only allow for a single request to be in flight for batched events.
    private var batchRequest: URLSessionDataTask?
    
    /// The task id corresponding to the background task.
    private var flushTaskId: UIBackgroundTaskIdentifier = .invalid
    
    /// A reference to the timer that's used to periodically flush events.
    private var flushTimer: Timer?
    
    // MARK: - Event queue operations
    /// The queue of analytics events.
    private lazy var queuedEvents: [AnalyticsData] = {
        guard let dataFromUserDefaults = UserDefaults.analyticsQueue else {
            return [AnalyticsData]()
        }
        return dataFromUserDefaults
    }()
    
    /// Persists the queue to `UserDefaults`.
    private func persistQueue() {
        UserDefaults.analyticsQueue = queuedEvents
    }
    
    /// Deletes the queue from `UserDefaults`.
    private func deleteQueue() {
        if let _ = UserDefaults.analyticsQueue {
            UserDefaults.analyticsQueue = nil
        }
    }
    
    /// Runs the parameter closure on the appropriate `DispatchQueue`.
    ///
    /// - Parameters:
    ///     - async: A boolean value that determines whether or not the closure is run asynchronously or not.
    ///     - isBackgroundTask: A boolean value that determines if the closure is run on the background tasks `DispatchQueue`.
    private func run(async: Bool = true,
                     isBackgroundTask: Bool = false,
                     closure: @escaping VoidClosure) {
        if isBackgroundTask {
            if async {
                backgroundQueue.async(execute: closure)
            } else {
                backgroundQueue.sync(execute: closure)
            }
        } else {
            if async {
                foregroundQueue.async(execute: closure)
            } else {
                foregroundQueue.sync(execute: closure)
            }
        }
    }
    
    /// Starts the analytics collection. Safe to be run from a background thread.
    private func start() {
        if hasBeenStarted { return }
        hasBeenStarted = true
        
        Analytics.log("Starting...")
        if Thread.isMainThread {
            configureFlushTimer()
        } else {
            DispatchQueue.main.sync {
                configureFlushTimer()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: { [weak self] _ in self?.applicationDidEnterBackground() })
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil, using: { [weak self] _ in self?.applicationWillTerminate() })
    }
    
    /// Stops analytics collection.
    private func stop() {
        if !hasBeenStarted { return }
        hasBeenStarted = false
        
        Analytics.log("Stopping...")
        NotificationCenter.default.removeObserver(self)
        batchRequest?.cancel()
        batchRequest = nil
        endBackgroundTask()
        deleteQueue()
    }
    
    /// Converts the parameter analytics substructures into a `AnalyticsData` object.
    ///
    /// - Parameters:
    ///     - event: An instance of `AnalyticsEvent` corresponding to the event that is to be tracked.
    ///     - location: An optional `Location` corresponding to the location the event occurred at.
    ///     - sourceLocation: An optional `Location` corresponding the source location of the event.
    ///     - object: An optional `AnalyticsTrackable` to provide context for the event.
    ///     - state: An optional `AnalyticsState` corresponding to the state of the event.
    /// - Returns: An instance of `AnalyticsData` with all of the parameters transformed.
    private func transform(event: AnalyticsEvent,
                           location: Location?,
                           sourceLocation: Location? = nil,
                           object: AnalyticsTrackable? = nil,
                           state: AnalyticsState? = nil) -> AnalyticsData {
        var sanitizedData: AnalyticsData
        
        if let objectAttributes = object?.attributes {
            sanitizedData = objectAttributes
        } else {
            sanitizedData = [:]
        }

        if let location = location {
            if let type = location.type {
                sanitizedData["location_type"] = type
            }
            
            if let identifier = location.identifier {
                sanitizedData["location_id"] = identifier
            }
        }
        
        if let sourceLocation = sourceLocation {
            if let type = sourceLocation.type {
                sanitizedData["source_location_type"] = type
            }
            if let identifier = sourceLocation.identifier {
                sanitizedData["source_location_id"] = identifier
            }
        }
        
        if let object = object {
            sanitizedData["object_type"] = object.type
            sanitizedData["object_id"] = object.identifier
            if let objectAttributes = object.attributes {
                sanitizedData = objectAttributes.merging(sanitizedData) { (_, new) in new }
            }
        }
        
        if let state = state {
            sanitizedData["state"] = state.rawValue
        }
        
        return [
            "name": event.name,
            "properties": sanitizedData,
            "timestamp": Date().roundedMillisecondsSince1970
        ]
    }
    
    /// Tracks analytics data.
    ///
    /// - Parameters:
    ///     - event: An instance of `AnalyticsEvent` corresponding to the event that is to be tracked.
    ///     - location: An `Location` corresponding to the location the event occurred at.
    ///     - sourceLocation: An optional `Location` corresponding the source location of the event.
    ///     - object: An optional `AnalyticsTrackable` to provide context for the event.
    ///     - state: An optional `AnalyticsState` corresponding to the state of the event.
    /// - Returns: An instance of `AnalyticsData` with all of the parameters transformed.
    func track(_ event: AnalyticsEvent,
                      location: Location? = nil,
                      sourceLocation: Location? = nil,
                      object: AnalyticsTrackable? = nil,
                      state: AnalyticsState? = nil) {
        guard enabled else { return }
        let eventData = transform(event: event,
                                  location: location,
                                  sourceLocation: sourceLocation,
                                  object: object,
                                  state: state)
        Analytics.log("Enqueueing data: \(eventData)")
        run { [weak self] in
            self?.queuePayload(eventData)
        }
    }
    
    /// Queues up the parameter payload to be sent.
    ///
    /// - Parameters:
    ///     - data: The analytics payload to queue.
    private func queuePayload(_ data: AnalyticsData) {
        // Remove the oldest element if the queue size has grown to be too big
        if queuedEvents.count > Constants.QueueDropSize {
            queuedEvents.removeFirst()
        }
        queuedEvents.append(data)
        persistQueue()
        flushQueueByLength()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Event flushing
    /// Flushes events from queue.
    ///
    /// - Parameters:
    ///     - size: The number of events to flush.
    private func flushQueueByMaxSize(_ size: Int) {
        run { [weak self] in
            guard let self = self else { return }
            
            if self.queuedEvents.isEmpty {
                Analytics.log("No queued network calls to flush.")
                self.endBackgroundTask()
                return
            }
            
            // API request is in progress so we return here
            if self.batchRequest != nil {
                Analytics.log("Network request in progress, no need to cancel.")
                return
            }
            
            var batchedEvents = self.queuedEvents
            if self.queuedEvents.count >= size {
                batchedEvents = Array(self.queuedEvents.prefix(size))
            }
            self.upload(batchedEvents)
        }
    }
    
    /**
     Flushes events from queue depending on how big the queue size is.
     
     If the queue size is greater than or equal to `Analytics.flushCount` and there's no current network request in flight, then the queue is flushed, otherwise nothing happens.
    */
    private func flushQueueByLength() {
        run { [weak self] in
            guard let self = self else { return }
            
            Analytics.log("Queue Length is \(self.queuedEvents.count)")
            if self.batchRequest == nil && self.queuedEvents.count >= Constants.flushCount {
                self.flush()
            }
        }
    }
    
    /**
        Configures a repeating timer to flush queue after a timeout.
     
        Uses `Analytics.flushTimerTimeout` to determine what time interval to use. This method ignores the preset count for the queue size to flush and flushes all events that are currently queued up.
    */
    private func configureFlushTimer() {
        flushTimer = Timer.scheduledTimer(timeInterval: Constants.flushTimerTimeout,
                                          target: self,
                                          selector: #selector(flush),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    /// Flushes all events from queue.
    @objc private func flush() {
        flushQueueByMaxSize(Constants.ForceFlushCount)
    }
    
    // MARK: - Network Uploading
    /// Uploads analytics data to the network.
    ///
    /// - Parameters:
    ///     - data: The array of analytics events to upload.
    private func upload(_ data: [AnalyticsData]) {        
        Analytics.log("Flushing \(data.count) of \(queuedEvents.count) queued API calls.")
        batchRequest = networkController.send(data, completionHandler: { [weak self] retry in
            guard let self = self else { return }
            self.run {
                if retry {
                    Analytics.log("Request failed")
                    self.batchRequest = nil
                    self.endBackgroundTask()
                    return
                }
                Analytics.log("Request succeeded")
                self.queuedEvents = self.queuedEvents.filter { !data.contains($0) }
                self.persistQueue()
                self.batchRequest = nil
                self.endBackgroundTask()
            }
        }, errorHandler: { [weak self] error in
            guard let self = self else { return }
            
            Analytics.log("Encountered error: \(error.localizedDescription)")
            self.run {
                self.batchRequest = nil
                self.endBackgroundTask()
            }
        })
    }
    
    // MARK: - Application Lifecycle
    /// Called when the application entered the background.
    private func applicationDidEnterBackground() {
        startBackgroundTask()
        flush()
    }
    
    /// Called when the application will terminate.
    private func applicationWillTerminate() {
        run { [weak self] in
            guard let self = self else { return }
            
            if !self.queuedEvents.isEmpty {
                self.persistQueue()
            }
        }
    }
    
    // MARK: - Background Tasks
    /// Starts a background task for running any analytics-related operations.
    private func startBackgroundTask() {
        endBackgroundTask()
        run(async: false, isBackgroundTask: true) { [weak self] in
            guard let self = self else { return }
            
            self.flushTaskId = UIApplication.shared.beginBackgroundTask(withName: Constants.BackgroundTaskIdentifier) {
                self.endBackgroundTask()
            }
            Analytics.log("Attempting to begin background task with id: \(self.flushTaskId)")
        }
    }
    
    /// Ends background task that was setup for running any analytics related operations.
    private func endBackgroundTask() {
        run(async: false, isBackgroundTask: true) { [weak self] in
            guard let self = self else { return }
            
            if self.flushTaskId != UIBackgroundTaskIdentifier.invalid {
                Analytics.log("Attempting to Ending background task with id: \(self.flushTaskId) ")
                UIApplication.shared.endBackgroundTask(self.flushTaskId)
            }
            self.flushTaskId = .invalid
        }
    }
}
