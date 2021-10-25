//
//  LocationEventReporterTests.swift
//  SDKHostAppTests
//
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
                XCTAssertEqual($0, .reported(region: regionEvent))
            }
            recordRegionEventExpectation.fulfill()
        }
        locationEventReporter.recordRegionEvent(regionEvent)
        wait(for: [recordRegionEventExpectation], timeout: 1.0, enforceOrder: true)
    }
    
    func testRegionStartUploadEvent() {
        let regionEventStartUploadExpectation = expectation(description: "Expect a region start upload inside closure.")
        let regionEvent = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let recordDate = Date()
        let uploadStartDate = Date(timeIntervalSinceNow: 10)

        locationEventReporter.recordRegionEvent(regionEvent, at: recordDate)

        locationEventReporter.closure = { events in
            events.forEach {
                let delay = uploadStartDate.timeIntervalSince(recordDate)
                XCTAssertEqual($0, .uploadAttempted(region: regionEvent, delay: delay))
            }
            regionEventStartUploadExpectation.fulfill()
        }
        
        locationEventReporter.regionEventsStartUpload([regionEvent], at: uploadStartDate)
        wait(for: [regionEventStartUploadExpectation], timeout: 1.0, enforceOrder: true)
    }
    
    func testRegionSuccessfulUploadEvent() {
        let regionEventSuccessfulUploadExpectation = expectation(description: "Expect a region successful upload event inside closure.")
        let regionEvent = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let startUploadDate = Date()
        let successfulUploadDate = Date(timeIntervalSinceNow: 10)

        locationEventReporter.regionEventsStartUpload([regionEvent], at: startUploadDate)

        locationEventReporter.closure = { events in
            events.forEach {
                let delay = successfulUploadDate.timeIntervalSince(startUploadDate)
                XCTAssertEqual($0, .uploadSuccessful(region: regionEvent, delay: delay))
            }
            regionEventSuccessfulUploadExpectation.fulfill()
        }
        
        locationEventReporter.regionEventsSuccessfulUpload([regionEvent], at: successfulUploadDate)
        
        wait(for: [regionEventSuccessfulUploadExpectation], timeout: 1.0, enforceOrder: true)
    }
    
    func testRegionFailedDueToNetworkErrorUploadEvent() {
        let regionEventFailedUploadExpectation = expectation(description: "Expect a region event upload failed due to network error inside closure.")
        let regionEvent = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let startUploadDate = Date()
        let failedUploadDate = Date(timeIntervalSinceNow: 10)

        locationEventReporter.regionEventsStartUpload([regionEvent], at: startUploadDate)

        locationEventReporter.closure = { events in
            events.forEach {
                let delay = failedUploadDate.timeIntervalSince(startUploadDate)
                XCTAssertEqual($0, .uploadFailed(region: regionEvent, error: .networkError, delay: delay))
            }
            regionEventFailedUploadExpectation.fulfill()
        }
        
        locationEventReporter.regionEventsErrorUpload([regionEvent], at: failedUploadDate, error: .networkError)
        
        wait(for: [regionEventFailedUploadExpectation], timeout: 1.0, enforceOrder: true)
    }
    
    func testRegionFailedDueToSanityThresholdEvent() {
        let regionEventFailedUploadExpectation = expectation(description: "Expect a region event failed upload due to sanity threshold inside closure.")
        let regionEvent = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let startUploadDate = Date()
        let failedUploadDate = Date(timeIntervalSinceNow: 10)

        locationEventReporter.regionEventsStartUpload([regionEvent], at: startUploadDate)

        locationEventReporter.closure = { events in
            events.forEach {
                let delay = failedUploadDate.timeIntervalSince(startUploadDate)
                XCTAssertEqual($0, .uploadFailed(region: regionEvent, error: .crossedSanityThreshold, delay: delay))
            }
            regionEventFailedUploadExpectation.fulfill()
        }
        
        locationEventReporter.regionEventsErrorUpload([regionEvent], at: failedUploadDate, error: .crossedSanityThreshold)
        
        wait(for: [regionEventFailedUploadExpectation], timeout: 1.0, enforceOrder: true)
    }
}
