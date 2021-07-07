//
//  LocationServiceTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

class LocationServiceTests: XCTestCase {
    
    var locationService: LocationService!
    fileprivate var regionEventsController: MockRegionEventsController!
    var regionEventsRegistry: RegionEventsRegistry!
    var connectionsRegistry: ConnectionsRegistry!
    var locationManager: MockCoreLocationManager!
    var regionsMonitor: RegionsMonitor!
    var eventPublisher: EventPublisher<SynchronizationTriggerEvent>!
    
    override class func setUp() {
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
    }
    
    override class func tearDown() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)
    }
    
    override func setUp() {
        super.setUp()
        
        locationManager = MockCoreLocationManager()
        regionEventsController = MockRegionEventsController(urlSession: .regionEventsURLSession)
        regionsMonitor = RegionsMonitor(locationManager: locationManager, allowsBackgroundLocationUpdates: true)
        regionEventsRegistry = RegionEventsRegistry()
        eventPublisher = EventPublisher<SynchronizationTriggerEvent>(publisherDispatchQueue: .init(label: "com.ifttt.location_service.event_publisher"))
        connectionsRegistry = ConnectionsRegistry()
        locationService = LocationService(regionsMonitor: regionsMonitor,
                                          regionEventsRegistry: regionEventsRegistry,
                                          connectionsRegistry: connectionsRegistry,
                                          sessionManager: .init(networkController: regionEventsController,
                                                                regionEventsRegistry: regionEventsRegistry),
                                          eventPublisher: eventPublisher)
    }
    
    override func tearDown() {
        super.tearDown()
        
        connectionsRegistry.removeAll(shouldNotify: false)
        regionEventsRegistry.removeAll()
        Keychain.resetIfNecessary(force: true)
        
        locationManager = nil
        regionsMonitor = nil
        regionEventsRegistry = nil
        eventPublisher = nil
        connectionsRegistry = nil
        locationService = nil
    }
    
    func test_willSync_no_location_triggers_not_authenticated() {
        // Test native service has no location triggers and is not authenticated. In this case, we clear out region events from RecordStorage.
        (0..<5).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }
        
        XCTAssertFalse(locationService.shouldParticipateInSynchronization(source: .regionsUpdate))
        XCTAssertTrue(regionEventsRegistry.getRegionEvents().isEmpty)
    }
    
    func test_willSync_no_location_triggers_authenticated() {
        // Test native service has no location triggers and is authenticated
        connectionsRegistry.removeAll(shouldNotify: false)
        Keychain.userToken = "TESTTOKEN"
        
        XCTAssertFalse(locationService.shouldParticipateInSynchronization(source: .regionsUpdate))
    }
    
    func test_willSync_location_triggers_authenticated() {
        // Test native service has location triggers and is authenticated
        var triggersSet = Set<Trigger>()
        triggersSet.insert(.location(region: LocationTestHelpers.IFTTTCircularRegion))
        let enabledConnection = LocationTestHelpers.generateConnection(with: .enabled, triggers: triggersSet)
        
        connectionsRegistry.update(with: enabledConnection, shouldNotify: false)
        Keychain.userToken = "TESTTOKEN"
        
        (0..<5).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }
        
        XCTAssertTrue(locationService.shouldParticipateInSynchronization(source: .regionsUpdate))
    }
    
    func test_willSync_no_location_triggers_authenticated_disabled_connection() {
        var triggersSet = Set<Trigger>()
        triggersSet.insert(.location(region: LocationTestHelpers.IFTTTCircularRegion))
        let disabled = LocationTestHelpers.generateConnection(with: .disabled, triggers: triggersSet)

        connectionsRegistry.update(with: disabled, shouldNotify: false)
        Keychain.userToken = "TESTTOKEN"
        
        XCTAssertFalse(locationService.shouldParticipateInSynchronization(source: .regionsUpdate))
    }
    
    func test_performSync_no_data_no_error() {
        let syncExpectation = expectation(description: "No region events should result in no new data.")
        
        locationService.performSynchronization { (newData, error) in
            XCTAssertFalse(newData)
            XCTAssertNil(error)
            syncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_performSync_less_than_sanity_threshold_no_error() {
        // Will complete with new data and cleared events if < LocationService.SanityThreshold events
        let syncExpectation = expectation(description: "Region event count less than sanity threshold should result in new data.")
        
        (0..<5).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }
        
        locationService.performSynchronization { (newData, error) in
            XCTAssertTrue(newData)
            XCTAssertNil(error)
            syncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_performSync_greater_than_equal_to_sanity_threshold_no_error() {
        // Will complete with new data and cleared events if there are >= than LocationService.SanityThreshold events
        let syncExpectation = expectation(description: "Region event count less than sanity threshold should result in new data.")
        
        (0..<25).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }
        
        locationService.performSynchronization { [weak self] (newData, error) in
            guard let self = self else {
                XCTAssert(false) // Something went wrong with getting a reference to self
                syncExpectation.fulfill()
                return
            }
            
            XCTAssertFalse(newData)
            XCTAssertNil(error)
            XCTAssertTrue(self.regionEventsRegistry.getRegionEvents().isEmpty)
            syncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test_performSync_error() {
        // Add some region events
        (0..<10).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }

        let syncExpectation = expectation(description: "Waiting for expectation to fulfill with error in uploading events.")
        regionEventsController.mockPostError = true
        locationService.performSynchronization { (newData, error) in
            XCTAssertFalse(newData)
            XCTAssertNotNil(error)
            syncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 120, handler: nil)
    }
    
    func test_performSync_no_new_data_retry_exhausted() {
        // Add some region events
        (0..<10).map { count -> RegionEvent in
            return RegionEvent(recordId: .init(),
                               kind: .entry,
                               occurredAt: .init(),
                               triggerSubscriptionId: "\(count)")
        }
        .forEach {
            regionEventsRegistry.add($0)
        }

        let syncExpectation = expectation(description: "Waiting for expectation to fulfill with error in uploading events.")
        regionEventsController.mockSucceeded = false
        locationService.performSynchronization { (newData, error) in
            XCTAssertFalse(newData)
            XCTAssertNotNil(error)
            syncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 120, handler: nil)
    }
    
    func test_record_enter_region_events() {
        let regions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                                         count: 100,
                                                                         radius: 100)
        let connectionsFromRegions = regions.map { region -> Connection.ConnectionStorage in
            var triggersSet = Set<Trigger>()
            triggersSet.insert(.location(region: region))
            return Connection.ConnectionStorage(id: UUID().uuidString,
                                                status: .enabled,
                                                activeUserTriggers: triggersSet,
                                                allTriggers: triggersSet)
        }
        locationService.start()
        locationService.updateRegions(from: Set(connectionsFromRegions))
        regions.forEach { region in
            let semaphore = DispatchSemaphore(value: 0)
            var actualTrigger: SynchronizationTriggerEvent?
            
            // Expect a sync trigger to get fired
            _ = eventPublisher.addSubscriber { (trigger) in
                actualTrigger = trigger
                semaphore.signal()
            }

            locationManager.delegate?.locationManager?(locationManager, didEnterRegion: region)
            
            let regionEvent = regionEventsRegistry.getRegionEvents().first { (event) -> Bool in
                event.triggerSubscriptionId == region.identifier
            }
            XCTAssertNotNil(regionEvent)
            XCTAssertEqual(regionEvent?.triggerSubscriptionId, region.identifier)
            XCTAssertEqual(regionEvent?.kind, .entry)

            if actualTrigger == nil {
                semaphore.wait()
                XCTAssertNotNil(actualTrigger)
                XCTAssertEqual(actualTrigger?.source, .regionsUpdate)
            } else {
                XCTAssertNotNil(actualTrigger)
                XCTAssertEqual(actualTrigger?.source, .regionsUpdate)
            }
        }
    }
    
    func test_record_exit_region_events() {
        let regions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                                         count: 100,
                                                                         radius: 100)
        let connectionsFromRegions = regions.map { region -> Connection.ConnectionStorage in
            var triggersSet = Set<Trigger>()
            triggersSet.insert(.location(region: region))
            return Connection.ConnectionStorage(id: UUID().uuidString,
                                                status: .enabled,
                                                activeUserTriggers: triggersSet,
                                                allTriggers: triggersSet)
        }
        locationService.start()
        locationService.updateRegions(from: Set(connectionsFromRegions))
        regions.forEach { region in
            let semaphore = DispatchSemaphore(value: 0)
            var actualTrigger: SynchronizationTriggerEvent?
            
            // Expect a sync trigger to get fired
            _ = eventPublisher.addSubscriber { (trigger) in
                actualTrigger = trigger
                semaphore.signal()
            }

            locationManager.delegate?.locationManager?(locationManager, didExitRegion: region)
            
            let regionEvent = regionEventsRegistry.getRegionEvents().first { (event) -> Bool in
                event.triggerSubscriptionId == region.identifier
            }
            XCTAssertNotNil(regionEvent)
            XCTAssertEqual(regionEvent?.triggerSubscriptionId, region.identifier)
            XCTAssertEqual(regionEvent?.kind, .exit)

            if actualTrigger == nil {
                semaphore.wait()
                XCTAssertNotNil(actualTrigger)
                XCTAssertEqual(actualTrigger?.source, .regionsUpdate)
            } else {
                XCTAssertNotNil(actualTrigger)
                XCTAssertEqual(actualTrigger?.source, .regionsUpdate)
            }
        }
    }
    
    func test_run_states() {
        XCTAssertEqual(locationService.state, .unknown)
        
        locationService.start()
        XCTAssertEqual(locationService.state, .running)
        
        locationService.start()
        XCTAssertEqual(locationService.state, .running)
        
        locationService.reset()
        XCTAssertEqual(locationService.state, .stopped)
        XCTAssertTrue(regionsMonitor.currentlyMonitoredRegions.isEmpty)
        XCTAssertTrue(regionEventsRegistry.getRegionEvents().isEmpty)
        
        locationService.reset()
        XCTAssertEqual(locationService.state, .stopped)
    }
    
    func test_connections_geofence_registration() {
        let enabledRegions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                                         count: 8,
                                                                         radius: 100)
        enabledRegions.map { region -> Connection in
            var triggersSet = Set<Trigger>()
            triggersSet.insert(.location(region: region))
            return LocationTestHelpers.generateConnection(with: .enabled, triggers: triggersSet)
        }
        .forEach {
            connectionsRegistry.update(with: $0)
        }
        
        locationService.start()
        enabledRegions.forEach {
            locationManager?.delegate?.locationManager?(locationManager, didEnterRegion: $0)
        }
        
        let registryEventsIds = Set(regionEventsRegistry.getRegionEvents().map { $0.triggerSubscriptionId })
        let enabledRegionsIds = Set(enabledRegions.map { $0.identifier })
        
        XCTAssertTrue(registryEventsIds.subtracting(enabledRegionsIds).isEmpty, "The set of registry event ids should have the same ids as the ones in the enabledRegions ids.")
    }
}

fileprivate class MockRegionEventsController: JSONNetworkController {
    var mockEvents: [RegionEvent] = []
    var mockPostError: Bool = false
    var mockSucceeded: Bool = true

    @discardableResult
    override func json(urlRequest: URLRequest, completionHandler: JSONNetworkController.CompletionClosure?) -> URLSessionDataTask {
        if mockPostError {
            completionHandler?(.failure(NSError(domain: NSURLErrorDomain, code: 0, userInfo: nil)))
        } else {
            var response = HTTPURLResponse.mock(statusCode: 200)
            if mockSucceeded {
                if let body = urlRequest.httpBody,
                   let json = try? JSONSerialization.jsonObject(with: body, options: .init()) as? [JSON] {
                    let regionEvents = json.compactMap { RegionEvent(json: $0) }
                    mockEvents.append(contentsOf: regionEvents)
                }
            } else {
                response = HTTPURLResponse.mock(statusCode: 500)
            }
            
            completionHandler?(.success(.init(httpURLResponse: response, data: .none)))
        }
        return URLSessionDataTaskMock(closure: nil)
    }
}

extension HTTPURLResponse {
    static func mock(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: "https://www.ifttt.com")!,
                               statusCode: statusCode,
                               httpVersion: nil,
                               headerFields: nil)!
    }
}

class URLSessionDataTaskMock: URLSessionDataTask {
    private let closure: VoidClosure?

    init(closure: VoidClosure?) {
        self.closure = closure
    }

    // We override the 'resume' method and simply call our closure
    // instead of actually resuming any task.
    override func resume() {
        closure?()
    }
    
    override func cancel() {
        closure?()
    }
}
