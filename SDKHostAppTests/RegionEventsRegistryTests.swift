//
//  RegionEventsRegistryTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest

@testable import IFTTTConnectSDK

class RegionEventsRegistryTests: XCTestCase {
    
    private var regionEventsRegistry = RegionEventsRegistry()

    override func setUp() {
        super.setUp()        
        regionEventsRegistry.removeAll()
    }

    func testGet() {
        // Since we reset registry before every test, the registry should be empty.
        assert(regionEventsRegistry.getRegionEvents().isEmpty)
        
        let event1 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "1")
        
        let event2 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "2")
        
        let event3 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "3")
        
        let event4 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "4")
        
        let events = [event1, event2, event3, event4]
        events.forEach { regionEventsRegistry.add($0) }
        
        assert(regionEventsRegistry.getRegionEvents().count == events.count)
    }
    
    func testRemove() {
        // Since we reset the registry before every test, the registry should be empty.
        assert(regionEventsRegistry.getRegionEvents().isEmpty)
        
        let event1 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "1")
        
        let event2 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "2")
        
        let event3 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "3")
        
        let event4 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "4")
        
        let events = [event1, event2, event3, event4]
        events.forEach { regionEventsRegistry.add($0) }
        
        regionEventsRegistry.remove([event1, event2])
        assert(regionEventsRegistry.getRegionEvents().count == 2)
        
        regionEventsRegistry.remove([event3, event4])
        assert(regionEventsRegistry.getRegionEvents().isEmpty)
    }
    
    func testRemoveAll() {
        // Since we reset the registry before every test, the registry should be empty.
        assert(regionEventsRegistry.getRegionEvents().isEmpty)
        
        let event1 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "1")
        
        let event2 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "2")
        
        let event3 = RegionEvent(recordId: .init(),
                                 kind: .exit,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "3")
        
        let event4 = RegionEvent(recordId: .init(),
                                 kind: .entry,
                                 occurredAt: .init(),
                                 triggerSubscriptionId: "4")
        
        let events = [event1, event2, event3, event4]
        events.forEach { regionEventsRegistry.add($0) }
        
        regionEventsRegistry.removeAll()
        assert(regionEventsRegistry.getRegionEvents().isEmpty)
    }
}
