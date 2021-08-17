//
//  SynchronizationSchedulerTests.swift
//  SDKHostAppTests
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation
import XCTest

@testable import IFTTTConnectSDK

class SynchronizationSchedulerTests: XCTestCase {
    private var syncScheduler: SynchronizationScheduler!
    private var eventPublisher: EventPublisher<SynchronizationTriggerEvent>!
    
    override func setUp() {
        eventPublisher = .init()
        syncScheduler = .init(manager: .init(subscribers: []), triggers: eventPublisher)
    }
    
    override func tearDown() {
        eventPublisher = nil
        syncScheduler = nil
    }
    
    func test_start() {
        syncScheduler.stop()
        syncScheduler.start(lifecycleSynchronizationOptions: .all)
        
        XCTAssertNotNil(syncScheduler.subscriberToken)
        XCTAssertTrue(!syncScheduler.applicationLifecycleNotificationCenterTokens.isEmpty)
        XCTAssertTrue(!syncScheduler.sdkGeneratedNotificationCenterTokens.isEmpty)
    }
    
    func test_stop() {
        syncScheduler.start(lifecycleSynchronizationOptions: .all)
        syncScheduler.stop()
        
        XCTAssertNil(syncScheduler.subscriberToken)
        XCTAssertTrue(syncScheduler.applicationLifecycleNotificationCenterTokens.isEmpty)
        XCTAssertTrue(syncScheduler.sdkGeneratedNotificationCenterTokens.isEmpty)
    }
}
