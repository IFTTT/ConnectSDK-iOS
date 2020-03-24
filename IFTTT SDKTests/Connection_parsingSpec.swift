//
//  Connection_parsingSpec.swift
//  IFTTT SDKTests
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import XCTest
@testable import IFTTT_SDK

class Connection_parsingSpec: XCTestCase {
    
    var connection: Connection!
    
    override func setUp() {
        let bundle = Bundle(for: Connection_parsingSpec.self)
        if let path = bundle.url(forResource: "fetch_connection_response",
                                 withExtension: "json"),
            let json = try? Data(contentsOf: path) {
            let parser = Parser(content: json)
            connection = Connection(parser: parser)
        }
    }
    
    func test_fetchConnectionResponse() {
        XCTAssertNotNil(connection)
        if connection == nil {
            return
        }
        
        let id = connection.id
        XCTAssertEqual(id, "LMhuSZW9")
        
        let name = connection.name
        XCTAssertEqual(name, "Make time for all of your favorite shows on Netflix")
        
        let details = connection.description
        XCTAssertEqual(details, "Traveling and forgot to notify us? Now you can show Amex your location and not have to worry about it before your next vacation. Let's collapse longer descriptions.")

        let coverImage1080 = connection.coverImage(size: .w1080)?.url?.absoluteString
        XCTAssertEqual(coverImage1080, "https://ifttt.com/1080w", "Cover image not found")
        
        let bestCoverImage = connection.coverImage(for: 1600, scale: 1)?.url?.absoluteString
        XCTAssertEqual(bestCoverImage, "https://ifttt.com/1440w", "Best fit cover image not found")
        
        let firstFeature = connection.features.first
        XCTAssertEqual(firstFeature?.title, "Effortlessly track time spent at work")
        XCTAssertEqual(firstFeature?.details, "Some random description for this feature")
        XCTAssertEqual(firstFeature?.iconURL?.absoluteString, "https://ifttt.com/value-prop-icons/clock.png", "Feature not found")
        
        let firstTrigger = connection.activeTriggers.first
        switch firstTrigger {
        case .location(let region):
            XCTAssertEqual(region.radius, 123.4567890)
            XCTAssertEqual(region.center.latitude, 12.45678920)
            XCTAssertEqual(region.center.longitude, -98.5432112)
            XCTAssertEqual(region.identifier, "somecoolidentifier")
        default:
            XCTFail("Expecting a location trigger")
        }
        
        if let firstNativePermission = connection.activePermissions.first {
            XCTAssertEqual(firstNativePermission, NativePermission.location)
        } else {
            XCTFail("Expecting a location permission to exist.")
        }
        
        XCTAssertEqual(connection.hasLocationTriggers, true)
        
        if let firstRegion = connection.locationRegions.first {
            XCTAssertEqual(firstRegion.radius, 123.4567890)
            XCTAssertEqual(firstRegion.center.latitude, 12.45678920)
            XCTAssertEqual(firstRegion.center.longitude, -98.5432112)
            XCTAssertEqual(firstRegion.identifier, "somecoolidentifier")
        } else {
            XCTFail("Expecting a region to be returned")
        }
    }
}
