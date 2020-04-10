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
         publisher = EventPublisher<Int>(queue: .global())
    }
    
    func testPublish() {
        let expectations = (0..<10).map { return XCTestExpectation(description: "\($0)") }
        
        let _ = publisher.addSubscriber { value in
            expectations[value].fulfill()
        }
        
        (0..<10).forEach { publisher.onNext($0) }
        wait(for: expectations, timeout: 20.0)
    }

    func testAddSubscriber() {
        let firstExpectation = XCTestExpectation(description: "First")
        let secondExpectation = XCTestExpectation(description: "Second")
        let thirdExpectation = XCTestExpectation(description: "Third")
        
        // This is necessary so that each expectation can get fulfilled one at a time instead of multiple expectations getting fulfilled at the same time.
        let fulfillDispatchQueue = DispatchQueue(label: "com.ifttt.ifttt_tests.fullfillQueue")
        
        let _ = publisher.addSubscriber { value in
            fulfillDispatchQueue.sync {
                firstExpectation.fulfill()
            }
        }

        let _ = publisher.addSubscriber { value in
            fulfillDispatchQueue.sync {
                secondExpectation.fulfill()
            }
        }
        
        let _ = publisher.addSubscriber { value in
            fulfillDispatchQueue.sync {
                thirdExpectation.fulfill()
            }
        }
        
        publisher.onNext(1)
        wait(for: [firstExpectation, secondExpectation, thirdExpectation], timeout: 20.0, enforceOrder: true)
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
