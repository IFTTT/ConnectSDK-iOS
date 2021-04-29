//
//  ConnectionsRegistryTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

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
        XCTAssertTrue(connectionsRegistry.getConnections().isEmpty)
        
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
        XCTAssertTrue(connectionsRegistry.getConnections().count == 1)
        XCTAssertTrue(connectionsRegistry.getConnections().first?.id == "12345")
        XCTAssertTrue(connectionsRegistry.getConnections().first?.status == .disabled)
        
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
        XCTAssertTrue(connectionsRegistry.getConnections().count == 1)
    }
    
    func testGetConnectionById() {
        // Since we reset the user defaults before every test, the registry should be empty.
        XCTAssertTrue(connectionsRegistry.getConnections().isEmpty)
        
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
        let connection = connectionsRegistry.getConnection(with: disabledConnection.id)
        XCTAssertNotNil(connection)
        
        let nilConnection = connectionsRegistry.getConnection(with: "unknown_connection_id")
        XCTAssertNil(nilConnection)
    }
    
    func testUpdateWithConnectionIds() {
        let connectionIds = (0..<5).map { _ in return UUID().uuidString }
        let expectation = self.expectation(forNotification: .ConnectionAddedNotification, object: nil, handler: nil)
        connectionsRegistry.addConnections(with: connectionIds, shouldNotify: true)
        wait(for: [expectation], timeout: 30.0)
        
        connectionsRegistry.getConnections().forEach { element in
            XCTAssertTrue(connectionIds.contains(element.id))
            XCTAssertEqual(element.status, .enabled)
            XCTAssertTrue(element.activeUserTriggers.isEmpty)
            XCTAssertTrue(element.allTriggers.isEmpty)
        }
        
        let allStatuses: [Connection.Status] = [.disabled, .enabled, .initial, .unknown]
        let statusMap = connectionIds.reduce([String: Connection.Status]()) { (map, id) -> [String: Connection.Status] in
            var map = map
            map[id] = allStatuses[Int.random(in: 0..<allStatuses.count)]
            return map
        }

        var triggers = Set<Trigger>()
        triggers.insert(.location(region: LocationTestHelpers.IFTTTCircularRegion))

        let connectionsWithTriggers = connectionIds.map { id -> Connection in
            return Connection(id: id,
                              name: "Test connection",
                              description: "Test connection description",
                              status: statusMap[id]!,
                              url: URL(string: "https://www.google.com")!,
                              coverImages: [:],
                              valuePropositionsParser: Parser(content: nil),
                              features: [],
                              services: [],
                              primaryService: .init(id: "123456", name: "Test service", shortName: "TS", isPrimary: true, templateIconURL: URL(string: "https://www.google.com")!, brandColor: .white, url: URL(string: "https://www.google.com")!),
                              activeUserTriggers: triggers)
        }
        
        connectionsWithTriggers.forEach { connectionsRegistry.update(with: $0) }
        connectionsWithTriggers.forEach { connection in
            let expectedStatus = statusMap[connection.id]!
            XCTAssertEqual(expectedStatus, connection.status)
            XCTAssertEqual(connection.activeUserTriggers, triggers)
        }
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
        XCTAssertTrue(connectionsRegistry.getConnections().contains(disabledConnectionStorage))
        
        disabledConnection.status = .enabled
        connectionsRegistry.update(with: disabledConnection, shouldNotify: false)
        XCTAssertTrue(connectionsRegistry.getConnections().contains(disabledConnectionStorage))
        
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
    
    func testUpdateNativeServiceEnabled() {
        let connectionId = "12345"
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
        connectionsRegistry.updateConnectionGeofencesEnabled(false, connectionId: connectionId)
        
        var connectionStorage = connectionsRegistry.getConnection(with: connectionId)!
        var enabled = connectionStorage.enabledNativeServiceMap[.location]!
        XCTAssertFalse(enabled, "Expecting enabled native service map to be false for location but got true")
        
        connectionsRegistry.updateConnectionGeofencesEnabled(true, connectionId: connectionId)
        connectionStorage = connectionsRegistry.getConnection(with: connectionId)!
        enabled = connectionStorage.enabledNativeServiceMap[.location]!
        XCTAssertTrue(enabled, "Expecting enabled native service map to be true for location but got false")
        
        
        connectionsRegistry.updateConnectionGeofencesEnabled(true, connectionId: "09876")
        connectionStorage = connectionsRegistry.getConnection(with: connectionId)!
        enabled = connectionStorage.enabledNativeServiceMap[.location]!
        XCTAssertTrue(enabled, "Expecting enabled native service map to be true for location but got false")
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
