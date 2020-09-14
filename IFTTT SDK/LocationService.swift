//
//  LocationService.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

/// Handles uploading analytics data to the network.
final class RegionEventsNetworkController {
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
    ///   - events: A `[AnalyticsEvent]` to send.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    func send(_ request: LocationService.Request, completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
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
                completionHandler(true)
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

/// Helps with processing regions from connections and handles storing and uploading location event updates from the system to IFTTT.
final class LocationService: NSObject, SynchronizationSubscriber {
    /// Used to monitor regions.
    private let regionsMonitor: RegionsMonitor
    private let regionEventsRegistry: RegionEventsRegistry
    private let connectionsRegistry: ConnectionsRegistry
    private let networkController = RegionEventsNetworkController()
    private let regionEventTriggerPublisher: EventPublisher<SynchronizationTriggerEvent>
    
    private var currentTask: URLSessionDataTask?
    
    private struct Constants {
        /// According to the CoreLocationManager monitoring docs, the system can only monitor a total of 20 regions.
        static let MaxCoreLocationManagerMonitoredRegionsCount = 20
        static let SanityThreshold = 20
    }
    
    /// Creates an instance of `LocationService`.
    ///
    /// - Parameters:
    ///     - allowsBackgroundLocationUpdates: Determines whether or not the location manager using in the service should allow for background location updates.
    /// - Returns: An initialized instance of `LocationService`.
    init(allowsBackgroundLocationUpdates: Bool,
         regionEventsRegistry: RegionEventsRegistry,
         connectionsRegistry: ConnectionsRegistry,
         eventPublisher: EventPublisher<SynchronizationTriggerEvent>) {
        
        self.regionsMonitor = RegionsMonitor(allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates)
        self.regionEventsRegistry = regionEventsRegistry
        self.connectionsRegistry = connectionsRegistry
        self.regionEventTriggerPublisher = eventPublisher
        
        super.init()

        start()
    }
    
    private func updateRegionsFromRegistry() {
        let regions: Set<CLCircularRegion> = connectionsRegistry.getConnections().reduce(.init()) { (currSet, store) -> Set<CLCircularRegion> in
            guard store.status == .enabled else { return currSet }
            var set = currSet
            store.locationRegions.forEach {
                set.insert($0)
            }
            return set
        }
        regionsMonitor.updateRegions(regions)
    }
    
    @objc private func connectionsChanged() {
        updateRegionsFromRegistry()
    }
    
    private func start() {
        updateRegionsFromRegistry()
        
        self.regionsMonitor.didEnterRegion = { region in
            self.recordRegionEvent(with: region, kind: .entry)
        }

        self.regionsMonitor.didExitRegion = { region in
            self.recordRegionEvent(with: region, kind: .exit)
        }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let event = SynchronizationTriggerEvent(source: .regionsUpdate,
                                                    backgroundFetchCompletionHandler: nil)
            
            self.regionEventTriggerPublisher.onNext(event)
            
            if let backgroundTaskIdentifier = backgroundTaskIdentifier, backgroundTaskIdentifier != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }
    
    private func processUpdate(with connections: Set<Connection.ConnectionStorage>) {
        var overlappingSet = Set<CLCircularRegion>()
        connections.forEach {
            $0.activeTriggers.forEach { trigger in
                switch trigger {
                case .location(let region): overlappingSet.insert(region)
                }
            }
        }

        regionsMonitor.updateRegions(overlappingSet)
    }
    
    // MARK: - SynchronizationSubscriber
    var name: String {
        return "LocationService"
    }
    
    func shouldParticipateInSynchronization(source: SynchronizationSource) -> Bool {
        let hasLocationTriggers = connectionsRegistry.getConnections().reduce(false) { (currentResult, connection) -> Bool in
            return currentResult || connection.hasLocationTriggers
        }
        let credentialProvider = UserAuthenticatedRequestCredentialProvider.standard

        let isLoggedIn = credentialProvider.userToken != nil
        if !(hasLocationTriggers && isLoggedIn) {
            regionEventsRegistry.removeAll()
        }
        return hasLocationTriggers &&
            credentialProvider.userToken != nil
    }
    
    private func exponentialBackoffTiming(for retryCount: Int) -> DispatchTimeInterval {
        let seconds = Int(pow(2, Double(retryCount)))
        return .seconds(seconds)
    }
    
    func performSynchronization(completion: @escaping (Bool, Error?) -> Void) {
        processUpdate(with: connectionsRegistry.getConnections())
        
        if currentTask != nil {
            completion(false, nil)
            return
        }
        
        let credentialProvider = UserAuthenticatedRequestCredentialProvider()
            
        let existingRegionEvents = regionEventsRegistry.getRegionEvents()
        if existingRegionEvents.count > Constants.SanityThreshold {
            regionEventsRegistry.remove(existingRegionEvents)
            completion(false, nil)
        } else if existingRegionEvents.count > 0 {
            performRequest(events: existingRegionEvents,
                           credentialProvider: credentialProvider,
                           completion: completion)
        } else {
            completion(false, nil)
        }
    }
    
    private func performRequest(events: [RegionEvent],
                                credentialProvider: ConnectionCredentialProvider,
                                numberOfRetries: Int = 3,
                                retryCount: Int = 0,
                                completion: @escaping (Bool, Error?) -> Void) {
        currentTask?.cancel()
        currentTask = nil
        currentTask = networkController.send(.uploadEvents(events, credentialProvider: credentialProvider), completionHandler: { [weak self] (success) in
            if success {
                self?.regionEventsRegistry.remove(events)
            }
            self?.currentTask = nil
            completion(success, nil)
        }, errorHandler: { [weak self] (error) in
            guard let self = self else { return }
            if (error as NSError).code == NSURLErrorCancelled {
                if retryCount == numberOfRetries {
                    completion(false, nil)
                }
                return
            }
            
            if retryCount < numberOfRetries {
                let count = retryCount + 1
                DispatchQueue.main.asyncAfter(deadline: .now() + self.exponentialBackoffTiming(for: count)) {
                    self.performRequest(events: events,
                                        credentialProvider: credentialProvider,
                                        numberOfRetries: numberOfRetries,
                                        retryCount: count,
                                        completion: completion)
                }
            } else {
                self.currentTask = nil
                completion(false, error)
            }
        })
        currentTask?.resume()
    }
}
