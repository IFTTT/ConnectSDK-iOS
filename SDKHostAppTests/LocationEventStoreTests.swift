//
//  LocationEventStoreTests.swift
//  SDKHostAppTests
//
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
    
    private func runAsserts(
        event: RegionEvent,
        eventStore: LocationEventStore,
        date: Date,
        correctState: LocationEventStore.EventState,
        expectRecordToBeNil: Bool
    ) {
        let record = eventStore[event.recordId.uuidString]
        if expectRecordToBeNil {
            XCTAssertNil(record)
        } else {
            XCTAssertNotNil(record)
            XCTAssertEqual(record?.date, date)
            XCTAssertEqual(record?.state, correctState)
        }
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
            runAsserts(
                event: $0,
                eventStore: eventStore,
                date: date,
                correctState: .recorded,
                expectRecordToBeNil: false
            )
        }
    }
    
    func testTrackEventUploadStartEvent() {
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        let eventUploadStartDate = Date()
        
        [event1, event2].forEach {
            eventStore.trackEventUploadStart($0, at: eventUploadStartDate)
            runAsserts(
                event: $0,
                eventStore: eventStore,
                date: eventUploadStartDate,
                correctState: .uploadStart,
                expectRecordToBeNil: false
            )
        }
    }
    
    func testTrackEventUploadSuccessEvent() {
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        let eventUploadStartDate = Date()
        let eventUploadSuccessDate = eventUploadStartDate.addingTimeInterval(4.0)
        
        [event1, event2].forEach {
            eventStore.trackEventUploadStart($0, at: eventUploadStartDate)
            eventStore.trackEventSuccessfulUpload($0, at: eventUploadSuccessDate)
            
            runAsserts(
                event: $0,
                eventStore: eventStore,
                date: eventUploadSuccessDate,
                correctState: .uploadSuccess,
                expectRecordToBeNil: true
            )
        }
    }
    
    func testTrackEventUploadNetworkErrorEvent() {
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        let eventErrorDate = Date()

        [event1, event2].forEach {
            eventStore.trackEventFailedUpload(
                $0,
                error: .networkError,
                at: eventErrorDate
            )
            runAsserts(
                event: $0,
                eventStore: eventStore,
                date: eventErrorDate,
                correctState: .uploadError,
                expectRecordToBeNil: false
            )
        }
    }
    
    func testTrackEventUploadErrorSanityThresholdCrossedEvent() {
        let event1 = RegionEvent(kind: .entry, triggerSubscriptionId: "1234")
        let event2 = RegionEvent(kind: .exit, triggerSubscriptionId: "1234")
        let eventErrorDate = Date()

        [event1, event2].forEach {
            eventStore.trackEventFailedUpload(
                $0,
                error: .crossedSanityThreshold,
                at: eventErrorDate
            )
            runAsserts(
                event: $0,
                eventStore: eventStore,
                date: eventErrorDate,
                correctState: .uploadError,
                expectRecordToBeNil: true
            )
        }
    }
}
