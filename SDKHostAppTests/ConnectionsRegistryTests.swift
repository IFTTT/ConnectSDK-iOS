//
//  ConnectionsRegistryTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTT_SDK

class ConnectionsRegistryTests: XCTestCase {
    private var connectionsRegistry = ConnectionsRegistry()
    
    override class func setUp() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
    }
    
    override class func tearDown() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)
    }
    
    override func setUp() {
        super.setUp()
        connectionsRegistry.removeAll()
    }

    func testGet() {
        // Since we reset the user defaults before every test, the registry should be empty.
        assert(connectionsRegistry.getConnections().isEmpty)
        
        let disabledConnection = Connection(id: "12345",
                                            name: "Test connection",
                                            description: "Test connection description",
                                            status: .disabled,
                                            url: URL(string: "https://www.google.com")!,
                                            coverImages: [:],
                                            valuePropositionsParser: Parser(content: nil),
                                            features: [],
                                            services: [],
                                            primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                                            activeUserTriggers: .init())
        
        connectionsRegistry.update(with: disabledConnection, shouldNotify: false)
        assert(connectionsRegistry.getConnections().isEmpty)
        
        let enabledConnection = Connection(id: "12345",
                                           name: "Test connection",
                                           description: "Test connection description",
                                           status: .enabled,
                                           url: URL(string: "https://www.google.com")!,
                                           coverImages: [:],
                                           valuePropositionsParser: Parser(content: nil),
                                           features: [],
                                           services: [],
                                           primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                                           activeUserTriggers: .init())
        
        connectionsRegistry.update(with: enabledConnection, shouldNotify: false)
        assert(connectionsRegistry.getConnections().count == 1)
    }
    
    func testUpdate() {
        var disabledConnection = Connection(id: "12345",
                                            name: "Test connection",
                                            description: "Test connection description",
                                            status: .disabled,
                                            url: URL(string: "https://www.google.com")!,
                                            coverImages: [:],
                                            valuePropositionsParser: Parser(content: nil),
                                            features: [],
                                            services: [],
                                            primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                                            activeUserTriggers: .init())
        let disabledConnectionStorage = Connection.ConnectionStorage(connection: disabledConnection)
        
        connectionsRegistry.update(with: disabledConnection, shouldNotify: false)
        assert(!connectionsRegistry.getConnections().contains(disabledConnectionStorage))
        
        disabledConnection.status = .enabled
        connectionsRegistry.update(with: disabledConnection, shouldNotify: false)
        assert(connectionsRegistry.getConnections().contains(disabledConnectionStorage))
        
        let enabledConnection = Connection(id: "123456",
                                           name: "Test connection",
                                           description: "Test connection description",
                                           status: .enabled,
                                           url: URL(string: "https://www.google.com")!,
                                           coverImages: [:],
                                           valuePropositionsParser: Parser(content: nil),
                                           features: [],
                                           services: [],
                                           primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                                           activeUserTriggers: .init())
        
        let expectation = self.expectation(forNotification: .ConnectionAddedNotification, object: nil, handler: nil)
        connectionsRegistry.update(with: enabledConnection, shouldNotify: true)
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testRemoveAll() {
        let enabledRegions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                                     count: 10,
                                                                     radius: 10)
        let enabledConnections = enabledRegions.map { region -> Connection in
            var triggersSet = Set<Trigger>()
            triggersSet.insert(.location(region: region))
            return LocationTestHelpers.generateConnection(with: .enabled, triggers: triggersSet)
        }
        
        
        let expectation = self.expectation(forNotification: .AllConnectionRemovedNotification, object: nil, handler: nil)
        enabledConnections.forEach { connectionsRegistry.update(with: $0) }
        connectionsRegistry.removeAll(shouldNotify: true)
        wait(for: [expectation], timeout: 30.0)
            
        XCTAssertTrue(connectionsRegistry.getConnectionsCount() == 0, "The connections registry is not empty")
    }
}
