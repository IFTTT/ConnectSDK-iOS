//
//  CLRegion+Parsing_spec.swift
//  IFTTT SDKTests
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import XCTest
import CoreLocation

@testable import IFTTT_SDK

class CLRegion_Parsing_spec: XCTestCase {

    func testIFTTTRegion() {
        let iftttRegion = CLCircularRegion(center: .init(latitude: 0.0, longitude: 0.0), radius: 100, identifier: "ifttt_somecoolidentifier")
        let nonIftttRegion = CLCircularRegion(center: .init(latitude: 10.0, longitude: 10.0), radius: 100, identifier: "somecoolnoniftttidentifier")
        
        assert(iftttRegion.isIFTTTRegion)
        assert(!nonIftttRegion.isIFTTTRegion)
    }
}
