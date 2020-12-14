//
//  RegionsMonitorTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest
import CoreLocation

@testable import IFTTT_SDK

class MockVisit: CLVisit {
    private var backingCoordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.backingCoordinate = coordinate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.backingCoordinate = .init(latitude: 0, longitude: 0)
        super.init(coder: coder)
    }
    
    override var arrivalDate: Date {
        return Date()
    }

    override var departureDate: Date {
        return Date()
    }

    override var coordinate: CLLocationCoordinate2D {
        return backingCoordinate
    }

    override var horizontalAccuracy: CLLocationAccuracy {
        return 0
    }
    
}

class MockCoreLocationManager: CLLocationManager {
    var isMonitoringVisits = false
    var shouldAllowBackgroundLocationUpdates = false
    static var overridingAuthorizationStatus: CLAuthorizationStatus = .authorizedAlways
    
    override var allowsBackgroundLocationUpdates: Bool {
        get {
            return shouldAllowBackgroundLocationUpdates
        }
        set {
            shouldAllowBackgroundLocationUpdates = newValue
        }
    }
    
    override var authorizationStatus: CLAuthorizationStatus {
        get {
            return MockCoreLocationManager.overridingAuthorizationStatus
        }
        set {
            MockCoreLocationManager.overridingAuthorizationStatus = newValue
        }
    }
    
    override class func authorizationStatus() -> CLAuthorizationStatus {
        return overridingAuthorizationStatus
    }
    
    override func startMonitoringVisits() {
        super.startMonitoringVisits()
        isMonitoringVisits = true
    }
    
    override func stopMonitoringVisits() {
        super.stopMonitoringVisits()
        isMonitoringVisits = false
    }
    
    func fakeEnteredRegion(_ region: CLRegion) {
        delegate?.locationManager?(self, didEnterRegion: region)
    }
    
    func fakeExitedRegion(_ region: CLRegion) {
        delegate?.locationManager?(self, didExitRegion: region)
    }
    
    func fakeVisit(_ coordinate: CLLocationCoordinate2D) {
        let visit = MockVisit(coordinate: coordinate)
        delegate?.locationManager?(self, didVisit: visit)
    }
}

struct LocationTestHelpers {
    static func generateRandomRegion(withStartCoordinate: CLLocationCoordinate2D, radius: CLLocationDistance) -> CLCircularRegion {
        let center = generateRandomCoordinates(withStartCoordinate: withStartCoordinate, radius: radius)
        let identifier = UUID().uuidString
        return CLCircularRegion(center: center,
                                radius: radius,
                                identifier: identifier)
    }

    static func generateRandomRegions(withStartCoordinate: CLLocationCoordinate2D, count: Int, radius: CLLocationDistance) -> [CLCircularRegion] {
        return (0..<count).map { curr -> CLCircularRegion in
            generateRandomRegion(withStartCoordinate: withStartCoordinate, radius: radius)
        }
    }
    
    static func generateRegions(withStartCoordinate: CLLocationCoordinate2D, count: Int, radius: CGFloat) -> [CLCircularRegion] {
        return (0..<count).map {
            let lat = withStartCoordinate.latitude + Double($0)
            let long = withStartCoordinate.longitude + Double($0)
            let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let identifier = UUID().uuidString
            return CLCircularRegion(center: center,
                                    radius: CLLocationDistance(radius),
                                    identifier: identifier)
        }
    }

    static func generateRandomCoordinates(withStartCoordinate: CLLocationCoordinate2D, radius: CLLocationDistance) -> CLLocationCoordinate2D {
        let lat = Double(arc4random() % 20) + Double(withStartCoordinate.latitude)
        let long = Double(arc4random() % 10) + Double(withStartCoordinate.longitude)
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    static func generateConnection(with status: Connection.Status, triggers: Set<Trigger>) -> Connection {
        return Connection(id: UUID().uuidString,
                          name: "Test connection",
                          description: "Test connection description",
                          status: status,
                          url: URL(string: "https://www.google.com")!,
                          coverImages: [:],
                          valuePropositionsParser: Parser(content: nil),
                          features: [],
                          services: [],
                          primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                          activeUserTriggers: triggers)
    }

    static let IFTTTCenterCoordinate = CLLocationCoordinate2D(latitude: 37.773972, longitude: -122.431297)
    static let IFTTTCircularRegion = CLCircularRegion(center: IFTTTCenterCoordinate,
                                                      radius: 100,
                                                      identifier: "IFTTTCircularRegion")
}

class RegionsMonitorTests: XCTestCase {
    private var regionsMonitor: RegionsMonitor!
    private let locationManager = MockCoreLocationManager()
    
    override func setUp() {
        regionsMonitor = RegionsMonitor(locationManager: locationManager, allowsBackgroundLocationUpdates: true)
        regionsMonitor.updateRegions([])
    }
    
    override func tearDown() {
        regionsMonitor.currentlyMonitoredRegions.forEach {
            if CLLocationManager.isMonitoringAvailable(for: type(of: $0)) {
                locationManager.stopMonitoring(for: $0)
            }
        }
    }
    
    func test_updateRegions() {
        var regions = LocationTestHelpers.generateRandomRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate, count: 10, radius: 100)
        
        // Test updating the list of regions with a brand new list of regions
        regionsMonitor?.updateRegions(regions)
        
        var setDifference = regionsMonitor.currentlyMonitoredRegions.subtracting(regions)
        XCTAssert(setDifference.isEmpty, "The difference \(setDifference) is not empty.")
        
        // Test updating the list of regions with an existing region identifier with a new coordinate
        let newRandomCoordinates = LocationTestHelpers.generateRandomCoordinates(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate, radius: 100)
        let firstRegion = regions.first!
        let updatedFirstRegion = CLCircularRegion(center: newRandomCoordinates,
                                                  radius: firstRegion.radius,
                                                  identifier: firstRegion.identifier)
        regions[0] = updatedFirstRegion
        regionsMonitor.updateRegions(regions)

        setDifference = regionsMonitor.currentlyMonitoredRegions.subtracting(regions)
        XCTAssert(setDifference.isEmpty, "The difference \(setDifference) is not empty.")
        
        regionsMonitor?.updateRegions([])
        XCTAssert(regionsMonitor.currentlyMonitoredRegions.isEmpty)
    }
    
    func test_significantLocationMonitoring() {
        let regions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                          count: 25,
                                                          radius: 100)
        regionsMonitor.updateRegions(regions)
        XCTAssert(locationManager.isMonitoringVisits)
        
        locationManager.fakeVisit(LocationTestHelpers.IFTTTCenterCoordinate)
        
        // Ensure that we're still monitoring significant location changes
        XCTAssert(locationManager.isMonitoringVisits)
        
        // The system can only monitor 20 geofences at a time. Ensure that we're only monitoring that many.
        XCTAssert(regionsMonitor.currentlyMonitoredRegions.count == RegionsMonitor.Constants.MaxCoreLocationManagerMonitoredRegionsCount)
        
        // Ensure that we're monitoring only the 20 closest regions to the faked user location.
        var closestRegions = Set(regions.closestRegions(to: LocationTestHelpers.IFTTTCenterCoordinate, count: RegionsMonitor.Constants.MaxCoreLocationManagerMonitoredRegionsCount))
        
        XCTAssert(closestRegions == regionsMonitor.currentlyMonitoredRegions)
        
        let fakeLocation2 = CLLocationCoordinate2D(latitude: regions.last!.center.latitude,
                                                   longitude: regions.last!.center.longitude)
        locationManager.fakeVisit(fakeLocation2)
        
        // Ensure that we're still monitoring significant location changes
        XCTAssert(locationManager.isMonitoringVisits)
        
        // We should still be monitoring a max of RegionsMonitor.MaxCoreLocationManagerMonitoredRegionsCount regions
        XCTAssert(regionsMonitor.currentlyMonitoredRegions.count == RegionsMonitor.Constants.MaxCoreLocationManagerMonitoredRegionsCount)
        
        // Ensure that we're monitoring only the RegionsMonitor.MaxCoreLocationManagerMonitoredRegionsCount closest regions to the faked user location.
        closestRegions = Set(regions.closestRegions(to: fakeLocation2,
                                                    count: RegionsMonitor.Constants.MaxCoreLocationManagerMonitoredRegionsCount))
        XCTAssert(closestRegions == regionsMonitor.currentlyMonitoredRegions)
    }
    
    func test_stopMonitoring() {
        let regions = LocationTestHelpers.generateRandomRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                                count: 10,
                                                                radius: 100)
        regionsMonitor?.updateRegions(regions)
        regionsMonitor?.stopMonitor()
  
        XCTAssert(regionsMonitor.currentlyMonitoredRegions.isEmpty, "CoreLocation should not be monitoring any regions at this point")
    }
    
    func test_regionClosureCallbacks() {
        let regions = LocationTestHelpers.generateRandomRegions(withStartCoordinate:
                                                                    LocationTestHelpers.IFTTTCenterCoordinate,
                                                                count: 100, radius: 100)
        let enterRegionExpectationsMap = regions
            .map { (expectation(description: "Enter region expectation for region: \($0.identifier)"), $0) }
            .reduce([:]) { (dict, tuple) -> [String: (XCTestExpectation, CLRegion)] in
                var dict = dict
                dict[tuple.1.identifier] = tuple
                return dict
            }
        
        let exitRegionExpectationsMap = regions
            .map { (expectation(description: "Exit region expectation for region: \($0.identifier)"), $0) }
            .reduce([:]) { (dict, tuple) -> [String: (XCTestExpectation, CLRegion)] in
                var dict = dict
                dict[tuple.1.identifier] = tuple
                return dict
            }
        
        let regionStartedMonitoringExpectationsMap = regions
            .map { (expectation(description: "Region started expectation for region: \($0.identifier)"), $0) }
            .reduce([:]) { (dict, tuple) -> [String: (XCTestExpectation, CLRegion)] in
                var dict = dict
                dict[tuple.1.identifier] = tuple
                return dict
            }
        
        regionsMonitor.didEnterRegion = {
            let tuple = enterRegionExpectationsMap[$0.identifier]
            tuple?.0.fulfill()
        }
        
        regionsMonitor.didExitRegion = {
            let tuple = exitRegionExpectationsMap[$0.identifier]
            tuple?.0.fulfill()
        }
        
        regionsMonitor.didStartMonitoringRegion = {
            let tuple = regionStartedMonitoringExpectationsMap[$0.identifier]
            tuple?.0.fulfill()
        }
        
        enterRegionExpectationsMap.keys.shuffled().forEach { (identifier) in
            if let enterRegion = enterRegionExpectationsMap[identifier]?.1 {
                locationManager.delegate?.locationManager?(locationManager, didEnterRegion: enterRegion)
            }
            
            if let exitRegion = enterRegionExpectationsMap[identifier]?.1 {
                locationManager.delegate?.locationManager?(locationManager, didExitRegion: exitRegion)
            }
            
            if let startMonitoringRegion = regionStartedMonitoringExpectationsMap[identifier]?.1 {
                locationManager.delegate?.locationManager?(locationManager, didStartMonitoringFor: startMonitoringRegion)
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        let nonRunningAuthorizationStatuses: [CLAuthorizationStatus] = [
            .authorizedWhenInUse,
            .denied,
            .notDetermined,
            .restricted,
        ]
        
        nonRunningAuthorizationStatuses.forEach { status in
            locationManager.delegate?.locationManager?(locationManager, didChangeAuthorization: status)
            XCTAssert(regionsMonitor.currentlyMonitoredRegions.isEmpty, "CoreLocation should not be monitoring any regions at this point")
            
            let regions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                              count: 25,
                                                              radius: 100)
            regionsMonitor.updateRegions(regions)
            
            XCTAssert(regionsMonitor.currentlyMonitoredRegions.isEmpty, "CoreLocation should not be monitoring any regions at this point")
            
            locationManager.delegate?.locationManager?(locationManager, didChangeAuthorization: .authorizedAlways)
            
            regionsMonitor.updateRegions(regions)
            
            let setDifference = regionsMonitor.currentlyMonitoredRegions.subtracting(regions)
            XCTAssert(setDifference.isEmpty, "The difference \(setDifference) is not empty.")
        }
    }
}

