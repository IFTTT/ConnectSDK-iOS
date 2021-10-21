//
//  LocationEventStoreTests.swift
//  SDKHostAppTests
//
//  Created by Siddharth Sathyam on 10/21/21.
//  Copyright © 2021 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

class LocationEventStoreTests: XCTestCase {
    private var eventStore = LocationEventStore()
    
    override func setUp() {
        super.setUp()
        eventStore.reset()
    }
    
    func testSubscript() {
        let date = Date()
        let events = (0...5).map { _ in RegionEvent(kind: .entry, triggerSubscriptionId: "1234") }
        
        events.forEach {
            eventStore.trackRecordedEvent($0, at: date)
        }
        
        events.forEach {
            let record = eventStore[$0.recordId.uuidString]
            XCTAssertNotNil(record)
            XCTAssertEqual(record?.date, date)
            XCTAssertEqual(record?.state, .recorded)
        }
    }
    
    func testDelay() {
        let date = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 0.5)
        let date3 = Date(timeIntervalSince1970: 0.9)
        let date4 = Date(timeIntervalSince1970: 1.5)
        
        let date2dateDiff = date2.timeIntervalSince(date)
        let date3date2Diff = date3.timeIntervalSince(date2)
        let date4date3Diff = date4.timeIntervalSince(date3)
        
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        
        eventStore.trackRecordedEvent(event1, at: date)
        eventStore.trackRecordedEvent(event2, at: date)
        
        XCTAssertEqual(eventStore.delay(for: event1, against: date2), date2dateDiff)
        XCTAssertEqual(eventStore.delay(for: event2, against: date2), date2dateDiff)
        
        eventStore.trackEventUploadStart(event1, at: date2)
        eventStore.trackEventUploadStart(event2, at: date2)
        
        XCTAssertEqual(eventStore.delay(for: event1, against: date3), date3date2Diff)
        XCTAssertEqual(eventStore.delay(for: event2, against: date3), date3date2Diff)
        
        eventStore.trackEventFailedUpload(event1, error: .networkError, at: date3)
        eventStore.trackEventFailedUpload(event2, error: .networkError, at: date3)
    
        XCTAssertEqual(eventStore.delay(for: event1, against: date4), date4date3Diff)
        XCTAssertEqual(eventStore.delay(for: event2, against: date4), date4date3Diff)
    }
    
    func testTrackRecordEvent() {
        let date = Date()
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        
        eventStore.trackRecordedEvent(event1, at: date)
        eventStore.trackRecordedEvent(event2, at: date)
        
        [event1, event2].forEach {
            let record = eventStore[$0.recordId.uuidString]
            XCTAssertNotNil(record)
            XCTAssertEqual(record?.date, date)
            XCTAssertEqual(record?.state, .recorded)
        }
    }
    
    func testTrackEventUploadEvent() {
        let date = Date()
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        
        eventStore.trackRecordedEvent(event1, at: date)
        eventStore.trackRecordedEvent(event2, at: date)
        
        [event1, event2].forEach {
            let record = eventStore[$0.recordId.uuidString]
            XCTAssertNotNil(record)
            XCTAssertEqual(record?.date, date)
            XCTAssertEqual(record?.state, .recorded)
        }
    }
}
