//
//  LocationEventReporterTests.swift
//  SDKHostAppTests
//
//  Created by Siddharth Sathyam on 10/21/21.
//  Copyright © 2021 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

class LocationEventReporterTests: XCTestCase {
    private let locationEventReporter = LocationEventReporter(eventStore: .init())
    
    override func tearDown() {
        super.tearDown()
        locationEventReporter.closure = nil
        locationEventReporter.reset()
    }
    
    
    func testRecordRegionEvent() {
        let recordRegionEventExpectation = expectation(description: "Expect a region event inside closure.")
        let regionEvent = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        
        locationEventReporter.closure = { events in
            events.forEach {
                XCTAssertEqual($0, .reported(event: regionEvent))
            }
            recordRegionEventExpectation.fulfill()
        }
        locationEventReporter.recordRegionEvent(regionEvent)
        wait(for: [recordRegionEventExpectation], timeout: 1.0, enforceOrder: true)
    }
}
