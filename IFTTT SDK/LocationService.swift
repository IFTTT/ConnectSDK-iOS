//
//  LocationService.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Desribes errors that are created by the network controllers in the SDK
enum NetworkControllerError: Error {
    /// The total retry attempts were exhausted.
    case exhaustedRetryAttempts
}

/// Handles uploading analytics data to the network.
class RegionEventsNetworkController {
    private let urlSession: URLSession

    /// Creates a `RegionEventsNetworkController`.
    convenience init() {
        self.init(urlSession: .regionEventsURLSession)
    }

    /// Creates a `RegionEventsNetworkController`.
    ///
    /// - Parameter urlSession: A `URLSession` to make request on.
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    /// A handler that is used when response is recieved from a network request.
    ///
    /// - Parameter Bool: A boolean value that corresponds to whether or not the request should be retried.
    typealias CompletionHandler = (Bool) -> Void
    
    /// A handler that is used when a error is recieved from a network request.
    ///
    /// - Parameter Error: The error resulting from the network request.
    typealias ErrorHandler = (Error) -> Void

    /// Sends an array of region events.
    ///
    /// - Parameters:
    ///   - events: A `[RegionEvent]` to send.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    open func send(_ events: [RegionEvent], using credentialProvider: ConnectionCredentialProvider, completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
        let request = LocationService.Request.uploadEvents(events,
                                                           credentialProvider: credentialProvider)
        return task(urlRequest: request.urlRequest, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /// Returns an initialized `URLSessionDataTask`.
    ///
    /// - Parameters:
    ///   - events: A `[AnalyticsEvent]` to send.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    private func task(urlRequest: URLRequest, completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
        let handler = { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                errorHandler(error)
                return
            }
            
            guard let httpURLResponse = response as? HTTPURLResponse else {
                completionHandler(false)
                return
            }

            // For 2xx response codes no retry is needed
            // For 3xx, 4xx, 5xx response codes, a retry is needed
            let isValidResponse = (200..<300).contains(httpURLResponse.statusCode)
            completionHandler(isValidResponse)
        }
        return urlSession.dataTask(with: urlRequest, completionHandler: handler)
    }
}

extension URLSession {
    /// The `URLSession` used to submit analytics data.
    static let regionEventsURLSession: URLSession =  {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = [
            "Content-Type" : "application/json"
        ]
        return URLSession(configuration: configuration)
    }()
}


extension LocationService {
    /// Handles network requests related to the `LocationService`.
    struct Request {
        
        /// The HTTP request method options.
        enum Method: String {
            
            /// The HTTP POST method.
            case POST = "POST"
        }
        
        /// The `Request`'s `URLRequest` that task are completed on.
        public let urlRequest: URLRequest
        
        /// A `Request` configured to upload an array of `RegionEvent`s
        ///
        /// - Parameters:
        ///   - evemts: The array of `RegionEvent`s to upload
        ///   - credentialProvider: An object that handle providing credentials for a request.
        /// - Returns: A `Request` configured to upload the region events.
        public static func uploadEvents(_ events: [RegionEvent], credentialProvider: ConnectionCredentialProvider) -> Request {
            let data = events.map { $0.toJSON(stripPrefix: true) }
            return Request(path: "/location_events", method: .POST, data: data, credentialProvider: credentialProvider)
        }
        
        private init(path: String,
                     method: Method,
                     data: [JSON],
                     credentialProvider: ConnectionCredentialProvider) {
            let url = API.locationBase.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpBody = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions())
            
            if let userToken = credentialProvider.userToken, !userToken.isEmpty {
                request.addIftttServiceToken(userToken)
            }
            
            self.urlRequest = request
        }
    }
}

/// Handles uploading region events to the backend. Handles retries and ensures that only one request is in flight at a single time.
class RegionEventsSessionManager {
    /// The network controller to use in uploading region events
    private let networkController: RegionEventsNetworkController
    /// The registry to use in getting region events
    private let regionEventsRegistry: RegionEventsRegistry
    /// A reference to the current upload network task.
    private(set) var currentTask: URLSessionDataTask?

    /// Creates an instance of `RegionEventsSessionManager`.
    ///
    /// - Parameters:
    ///     - networkController: An instance of `RegionEventsNetworkController` used performing the upload of region events.
    ///     - regionEventsRegistry: An instance of `RegionEventsRegistry`.
    init(networkController: RegionEventsNetworkController,
         regionEventsRegistry: RegionEventsRegistry) {
        self.networkController = networkController
        self.regionEventsRegistry = regionEventsRegistry
    }
    
    /// Resets the session manager. Performs any cleanup work as necessary.
    func reset() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    private func exponentialBackoffTiming(for retryCount: Int) -> DispatchTimeInterval {
        let seconds = Int(pow(2, Double(retryCount)))
        return .seconds(seconds)
    }
    
    /// Uploads region events. Can handle multiple retry with exponential backoff timing.
    ///
    /// - Parameters:
    ///     - events: The array of `RegionEvent` to upload
    ///     - credentialProvider: A object conforming to `ConnectionCredentialProvider` to be used in making sure request is authenticated
    ///     - numberOfRetries: The number of times to retry a request given a failed response.
    ///     - retryCount: The total amount of retries that have occurred so far.
    ///     - completion: The closure that's invoked after a successful response, an error response, or a failed response after `numberOfRetries` retry attempts.
    func upload(events: [RegionEvent],
                credentialProvider: ConnectionCredentialProvider,
                numberOfRetries: Int = 3,
                retryCount: Int = 0,
                completion: @escaping (Bool, Error?) -> Void) {
        currentTask?.cancel()
        currentTask = nil
        ConnectButtonController.synchronizationLog("Uploading region events: \(events)")
        
        let successClosure: VoidClosure = { [weak self] in
            guard let self = self else { return }

            ConnectButtonController.synchronizationLog("Successfully uploaded region events: \(events)")
            self.regionEventsRegistry.remove(events)
            self.currentTask = nil
            completion(true, nil)
        }
        
        let failureClosure: (Int, Int) -> Void = { [weak self] retryCount, numberOfRetries in
            guard let self = self else { return }
            
            if retryCount < numberOfRetries {
                let count = retryCount + 1
                ConnectButtonController.synchronizationLog("Failed to upload region events: \(events). Will retry \(numberOfRetries - retryCount) more times.")
                DispatchQueue.main.asyncAfter(deadline: .now() + self.exponentialBackoffTiming(for: count)) {
                    self.upload(events: events,
                                credentialProvider: credentialProvider,
                                numberOfRetries: numberOfRetries,
                                retryCount: count,
                                completion: completion)
                }
            } else {
                ConnectButtonController.synchronizationLog("Failed to upload region events: \(events) after \(retryCount) retry attempts. Will try again on the next synchronization.")
                self.currentTask = nil
                completion(false, NetworkControllerError.exhaustedRetryAttempts)
            }
        }
        
        currentTask = networkController.send(events, using: credentialProvider, completionHandler: { (success) in
            if success {
                successClosure()
            } else {
                failureClosure(retryCount, numberOfRetries)
            }
        }, errorHandler: { error in
            if (error as NSError).code == NSURLErrorCancelled {
                if retryCount == numberOfRetries {
                    completion(false, nil)
                }
                return
            }
            
            failureClosure(retryCount, numberOfRetries)
        })
        currentTask?.resume()
    }
}


/// Helps with processing regions from connections and handles storing and uploading location event updates from the system to IFTTT.
final class LocationService: NSObject, SynchronizationSubscriber {
    /// Used to monitor regions.
    private let regionsMonitor: RegionsMonitor
    /// Stores region events that the regions monitor outputs
    private let regionEventsRegistry: RegionEventsRegistry
    /// Stores the connections that are being monitored by the SDK
    private let connectionsRegistry: ConnectionsRegistry
    /// Handles uploading region events to the backend
    private let sessionManager: RegionEventsSessionManager
    /// The `EventPublisher<SynchronizationTriggerEvent>` that handles publishing synchronization events to listeners
    private let regionEventTriggerPublisher: EventPublisher<SynchronizationTriggerEvent>
    /// Determines whether or not a 0.1 second delay should be applied before publishing synchronization events
    private let applyDelayOnSyncTrigger: Bool
        
    struct Constants {
        static let SanityThreshold = 20
    }
    
    /// Creates an instance of `LocationService`.
    ///
    /// - Parameters:
    ///     - regionsMonitor: An instance of `RegionsMonitor` that allows for regions to be monitored.
    ///     - regionEventsRegistry: An instance of `RegionEventsRegistry` that allows for the storage of region events.
    ///     - connectionsRegistry: An instance of `ConnectionsRegistry` that determines which connections are currently being monitored by the SDK.
    ///     - sessionManager: An instance of `RegionEventsSessionManager` that uploads region events to the backend.
    ///     - eventPublisher: An instance of `EventPublisher<SynchronizationTriggerEvent>` that handles publishing sync events to listeners.
    ///     - applyDelayOnSyncTrigger: Determines whether or not a 0.1 second delay should be applied to trigger syncs. Defaults to `true`.
    /// - Returns: An initialized instance of `LocationService`.
    init(regionsMonitor: RegionsMonitor,
         regionEventsRegistry: RegionEventsRegistry,
         connectionsRegistry: ConnectionsRegistry,
         sessionManager: RegionEventsSessionManager,
         eventPublisher: EventPublisher<SynchronizationTriggerEvent>,
         applyDelayOnSyncTrigger: Bool = true) {
        self.regionsMonitor = regionsMonitor
        self.regionEventsRegistry = regionEventsRegistry
        self.connectionsRegistry = connectionsRegistry
        self.sessionManager = sessionManager
        self.regionEventTriggerPublisher = eventPublisher
        
        self.applyDelayOnSyncTrigger = applyDelayOnSyncTrigger
        super.init()
    }
    
    private func updateRegionsFromRegistry() {
        updateRegions(from: connectionsRegistry.getConnections())
    }
    
    func updateRegions(from connections: Set<Connection.ConnectionStorage>) {
        let regions: Set<CLCircularRegion> = connections.reduce(.init()) { (currSet, store) -> Set<CLCircularRegion> in
            guard store.status == .enabled else { return currSet }
            var set = currSet
            store.locationRegions.forEach {
                set.insert($0)
            }
            return set
        }
        regionsMonitor.updateRegions(Array(regions))
    }
    
    private(set) var state: RunState = .unknown
    
    func start() {
        if state == .running { return }
        
        updateRegionsFromRegistry()
        
        self.regionsMonitor.didEnterRegion = { region in
            ConnectButtonController.synchronizationLog("User entered region: \(region)")
            self.recordRegionEvent(with: region, kind: .entry)
        }

        self.regionsMonitor.didExitRegion = { region in
            ConnectButtonController.synchronizationLog("User exited region: \(region)")
            self.recordRegionEvent(with: region, kind: .exit)
        }
        
        self.regionsMonitor.didStartMonitoringRegion = { region in
            ConnectButtonController.synchronizationLog("Did start monitoring region: \(region)")
        }
        
        self.regionsMonitor.monitoringDidFail = { region, error in
            ConnectButtonController.synchronizationLog("Did fail monitoring region: \(String(describing: region)). Error: \(error)")
        }
        
        state = .running
    }
    
    private func recordRegionEvent(with region: CLRegion, kind: RegionEvent.Kind) {
        var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            guard let identifier = backgroundTaskIdentifier else { return }
            if identifier != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        })
        
        let event = RegionEvent(kind: kind, triggerSubscriptionId: region.identifier)
        regionEventsRegistry.add(event)
        
        let closure = {
            let event = SynchronizationTriggerEvent(source: .regionsUpdate,
                                                    backgroundFetchCompletionHandler: nil)
            
            self.regionEventTriggerPublisher.onNext(event)
            
            if let backgroundTaskIdentifier = backgroundTaskIdentifier, backgroundTaskIdentifier != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }

        if applyDelayOnSyncTrigger {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: closure)
        } else {
            closure()
        }
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "LocationService"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        let hasLocationTriggers = connectionsRegistry.getConnections().reduce(false) { (currentResult, connection) -> Bool in
            return currentResult || connection.hasLocationTriggers
        }
        let hasLocationEvents = !regionEventsRegistry.getRegionEvents().isEmpty
        let credentialProvider = UserAuthenticatedRequestCredentialProvider.standard

        let isLoggedIn = credentialProvider.userToken != nil
        if !(hasLocationTriggers && isLoggedIn) {
            regionEventsRegistry.removeAll()
        }
        return hasLocationTriggers &&
            hasLocationEvents &&
            isLoggedIn
    }

    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        if sessionManager.currentTask != nil {
            completion(false, nil)
            return
        }
        
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
            
        let existingRegionEvents = regionEventsRegistry.getRegionEvents()
        if existingRegionEvents.count > Constants.SanityThreshold {
            regionEventsRegistry.remove(existingRegionEvents)
            completion(false, nil)
        } else if existingRegionEvents.count > 0 {
            sessionManager.upload(events: existingRegionEvents,
                                  credentialProvider: credentialProvider,
                                  completion: completion)
        } else {
            completion(false, nil)
        }
    }
    
    /// Resets the location service.
    func reset() {
        // Empty monitored regions
        regionsMonitor.reset()
        
        // Remove all registered events
        regionEventsRegistry.removeAll()
        
        // Reet the session manager
        sessionManager.reset()
        
        // Set the state to stopped
        state = .stopped
    }
}
