//
//  ConnectionsRegistryTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTT_SDK

class ConnectionsRegistryTests: XCTestCase {

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "ConnectionsRegistry.ConnectionsUserDefaultKey")
    }

    func testGet() {
        // Since we reset the user defaults before every test, the registry should be empty.
        assert(ConnectionsRegistry.shared.getConnections().isEmpty)
        
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
                                            activeTriggers: .init(),
                                            activePermissions: .init())
        
        ConnectionsRegistry.shared.update(with: disabledConnection, shouldNotify: false)
        assert(ConnectionsRegistry.shared.getConnections().isEmpty)
        
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
                                           activeTriggers: .init(),
                                           activePermissions: .init())
        
        ConnectionsRegistry.shared.update(with: enabledConnection, shouldNotify: false)
        assert(ConnectionsRegistry.shared.getConnections().count == 1)
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
                                            activeTriggers: .init(),
                                            activePermissions: .init())
        
        ConnectionsRegistry.shared.update(with: disabledConnection, shouldNotify: false)
        assert(!ConnectionsRegistry.shared.getConnections().contains(disabledConnection.id))
        
        disabledConnection.status = .enabled
        ConnectionsRegistry.shared.update(with: disabledConnection, shouldNotify: false)
        assert(ConnectionsRegistry.shared.getConnections().contains(disabledConnection.id))
        
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
                                           activeTriggers: .init(),
                                           activePermissions: .init())
        
        let expectation = self.expectation(forNotification: .ConnectionsChangedNotification, object: nil, handler: nil)
        ConnectionsRegistry.shared.update(with: enabledConnection, shouldNotify: true)
        wait(for: [expectation], timeout: 30.0)
    }
}
