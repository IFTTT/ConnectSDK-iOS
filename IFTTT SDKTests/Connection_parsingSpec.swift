//
//  Connection_parsingSpec.swift
//  IFTTT SDKTests
//
//  Created by Jon Chmura on 4/24/19.
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
        
        let coverImage1080 = connection.coverImage(size: .w1080)?.url?.absoluteString
        XCTAssertEqual(coverImage1080, "https://ifttt.com/1080w", "Cover image not found")
        
        let bestCoverImage = connection.coverImage(for: 1600, scale: 1)?.url?.absoluteString
        XCTAssertEqual(bestCoverImage, "https://ifttt.com/1440w", "Best fit cover image not found")
        
        let valueProp = connection.valuePropositions.first
        XCTAssertEqual(valueProp?.details, "Automatically sync your Netflix favorites to your seat", "Value prop not found")
        XCTAssertEqual(valueProp?.iconURL?.absoluteString, "https://ifttt.com/value-prop-icons/heart.png", "Value prop not found")
    }
}
