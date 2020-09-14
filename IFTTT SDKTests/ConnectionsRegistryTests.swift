//
//  ConnectionsRegistryTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTT_SDK

class ConnectionsRegistryTests: XCTestCase {

    private var connectionsRegistry: ConnectionsRegistry!
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "ConnectionsRegistry.ConnectionsUserDefaultKey")
        connectionsRegistry = ConnectionsRegistry()
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
                                            activeTriggers: .init())
        
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
                                           activeTriggers: .init())
        
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
                                            activeTriggers: .init())
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
                                           activeTriggers: .init())
        
        let expectation = self.expectation(forNotification: .ConnectionAddedNotification, object: nil, handler: nil)
        connectionsRegistry.update(with: enabledConnection, shouldNotify: true)
        wait(for: [expectation], timeout: 30.0)
    }
}
