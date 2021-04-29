//
//  EventPublisherTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

class EventPublisherTests: XCTestCase {
    var publisher: EventPublisher<Int>!
    
    override func setUp() {
         publisher = EventPublisher<Int>()
    }

    func testAddSubscriber() {
        let addSubscriberExpectation = expectation(description: "verify_added_subscriber_gets_invoked_with_value")
        addSubscriberExpectation.assertForOverFulfill = true
        publisher.addSubscriber { value in
            addSubscriberExpectation.fulfill()
        }
        publisher.onNext(1)
        wait(for: [addSubscriberExpectation], timeout: 1.0)
    }
    
    func testPublish() {
        let expectationCount = 100
        let expectations = (0..<expectationCount).map { return expectation(description: "\($0)") }
        
        publisher.addSubscriber { value in
            expectations[value].fulfill()
        }
        
        (0..<expectationCount).forEach {
            publisher.onNext($0)
        }
        wait(for: expectations, timeout: 20.0)
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
