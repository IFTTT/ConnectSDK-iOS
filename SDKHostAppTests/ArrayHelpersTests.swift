//
//  ArrayHelpersTests.swift
//  SDKHostAppTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest
import CoreLocation

@testable import IFTTTConnectSDK

class ArrayHelpersTests: XCTestCase {
    func testClosestRegionsToLocation() throws {
        let regions = LocationTestHelpers.generateRegions(withStartCoordinate: LocationTestHelpers.IFTTTCenterCoordinate,
                                                          count: 50,
                                                          radius: 100)
        let iftttLocation = LocationTestHelpers.IFTTTCenterCoordinate
                
        let twentyClosestRegions = regions
            .shuffled()
            .closestRegions(to: iftttLocation,
                            count: 20)
        
        XCTAssert(regions.keepFirst(20) == twentyClosestRegions)
        
        let thirtyClosestRegions = regions
            .shuffled()
            .closestRegions(to: iftttLocation,
                            count: 30)
        XCTAssert(regions.keepFirst(30) == thirtyClosestRegions)
    }
}
