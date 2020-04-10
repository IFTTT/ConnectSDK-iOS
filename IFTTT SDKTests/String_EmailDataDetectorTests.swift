//
//  String+EmailDataDetectorTests.swift
//  IFTTT SDKTests
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import XCTest
@testable import IFTTT_SDK

class StringEmailDataDetectorTests: XCTestCase {
    let emailString = "hello@ifttt.com"
    let nonEmailString = "Ten minutes left to execute our plan. Where’s everyone else? Playing Spiderman."
    let blockMixedText = "Ten minutes left to execute our plan. Where’s everyone else? Playing Spiderman. Reach out to hello@ifttt.com"
    let anotherBlockMixedText = "hello@ifttt.com Ten minutes left to execute our plan. Where’s everyone else? Playing Spiderman."
    let multipleEmails = "hello@ifttt.com, feedback@ifttt.com"
    let nonTraditionalEmailAddress = "hello+mike.amu_dsen@ifttt.com"
    
    func testIsEmail() {
        XCTAssertEqual(emailString.isValidEmail, true)
        XCTAssertEqual(nonEmailString.isValidEmail, false)
        XCTAssertEqual(blockMixedText.isValidEmail, false)
        XCTAssertEqual(anotherBlockMixedText.isValidEmail, false)
        XCTAssertEqual(multipleEmails.isValidEmail, false)
        XCTAssertEqual(nonTraditionalEmailAddress.isValidEmail, true)
    }
}
