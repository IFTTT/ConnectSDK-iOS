//
//  EventPublisherTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTT_SDK

class EventPublisherTests: XCTestCase {
    var publisher: EventPublisher<Int>!
    
    override func setUp() {
         publisher = EventPublisher<Int>()
    }

    func testAddSubscriber() {
        let expectationCount = 100
        let expectations = (0..<expectationCount).map { return XCTestExpectation(description: "\($0)") }
        
        (0..<expectationCount).forEach { count in
            publisher.addSubscriber { value in
                expectations[count].fulfill()
            }
        }
        publisher.onNext(1)
        wait(for: expectations, timeout: 20.0, enforceOrder: true)
    }
    
    func testPublish() {
        let expectationCount = 100
        let expectations = (0..<expectationCount).map { return XCTestExpectation(description: "\($0)") }
        
        publisher.addSubscriber { value in
            expectations[value].fulfill()
        }
        
        (0..<expectationCount).forEach { publisher.onNext($0) }
        wait(for: expectations, timeout: 20.0, enforceOrder: true)
    }

    func testRemoveSubscriber() {
        let firstExpectation = XCTestExpectation(description: "Subscribed and outputted value. Should only get fulfilled once")
        firstExpectation.assertForOverFulfill = true
        
        let subscriberUUID = publisher.addSubscriber { value in
            firstExpectation.fulfill()
        }

        publisher.onNext(1)
        publisher.removeSubscriber(subscriberUUID)
        publisher.onNext(1)
        wait(for: [firstExpectation], timeout: 20.0)
    }
}
