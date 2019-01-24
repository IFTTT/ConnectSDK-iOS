//
//  TypeStyleTests.swift
//  IFTTT SDKTests
//
//  Created by Michael Amundsen on 1/24/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import XCTest
@testable import IFTTT_SDK

@available(iOS 10.0, *)
class TypeStyleTests: XCTestCase {

     func testH1() {
        let h1 = TypeStyle.h1()
        let modifiedWeight = TypeStyle.h1(weight: .medium)
        let nonDynamic = TypeStyle.h1(isDynamic: false)
        let callout = TypeStyle.h1(isCallout: true)
        let custom = TypeStyle.h1(weight: .demiBold, isDynamic: false, isCallout: true)
        
        if #available(iOS 11, *) {
            XCTAssertEqual(h1, TypeStyle(weight: .bold, size: 36, isDynamic: true, style: .largeTitle))
            XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 36, isDynamic: true, style: .largeTitle))
            XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 36, isDynamic: false, style: .largeTitle))
            XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 36, isDynamic: true, style: .callout))
            XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 36, isDynamic: false, style: .callout))
        } else {
            XCTAssertEqual(h1, TypeStyle(weight: .bold, size: 36, isDynamic: true, style: .title1))
            XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 36, isDynamic: true, style: .title1))
            XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 36, isDynamic: false, style: .title1))
            XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 36, isDynamic: true, style: .callout))
            XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 36, isDynamic: false, style: .callout))
        }
    }

     func testH2() {
        let h2 = TypeStyle.h2()
        let modifiedWeight = TypeStyle.h2(weight: .medium)
        let nonDynamic = TypeStyle.h2(isDynamic: false)
        let callout = TypeStyle.h2(isCallout: true)
        let custom = TypeStyle.h2(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(h2, TypeStyle(weight: .bold, size: 30, isDynamic: true, style: .title1))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 30, isDynamic: true, style: .title1))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 30, isDynamic: false, style: .title1))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 30, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 30, isDynamic: false, style: .callout))
    }


     func testH3() {
        let h3 = TypeStyle.h3()
        let modifiedWeight = TypeStyle.h3(weight: .medium)
        let nonDynamic = TypeStyle.h3(isDynamic: false)
        let callout = TypeStyle.h3(isCallout: true)
        let custom = TypeStyle.h3(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(h3, TypeStyle(weight: .bold, size: 28, isDynamic: true, style: .title2))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 28, isDynamic: true, style: .title2))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 28, isDynamic: false, style: .title2))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 28, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 28, isDynamic: false, style: .callout))
    }


     func testH4() {
        let h4 = TypeStyle.h4()
        let modifiedWeight = TypeStyle.h4(weight: .medium)
        let nonDynamic = TypeStyle.h4(isDynamic: false)
        let callout = TypeStyle.h4(isCallout: true)
        let custom = TypeStyle.h4(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(h4, TypeStyle(weight: .bold, size: 24, isDynamic: true, style: .title3))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 24, isDynamic: true, style: .title3))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 24, isDynamic: false, style: .title3))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 24, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 24, isDynamic: false, style: .callout))
    }


     func testH5() {
        let h5 = TypeStyle.h5()
        let modifiedWeight = TypeStyle.h5(weight: .medium)
        let nonDynamic = TypeStyle.h5(isDynamic: false)
        let callout = TypeStyle.h5(isCallout: true)
        let custom = TypeStyle.h5(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(h5, TypeStyle(weight: .bold, size: 20, isDynamic: true, style: .headline))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 20, isDynamic: true, style: .headline))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 20, isDynamic: false, style: .headline))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 20, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 20, isDynamic: false, style: .callout))
    }


     func testH6() {
        let h6 = TypeStyle.h6()
        let modifiedWeight = TypeStyle.h6(weight: .medium)
        let nonDynamic = TypeStyle.h6(isDynamic: false)
        let callout = TypeStyle.h6(isCallout: true)
        let custom = TypeStyle.h6(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(h6, TypeStyle(weight: .bold, size: 18, isDynamic: true, style: .subheadline))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 18, isDynamic: true, style: .subheadline))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 18, isDynamic: false, style: .subheadline))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 18, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 18, isDynamic: false, style: .callout))
    }


     func testBody() {
        let body = TypeStyle.body()
        let modifiedWeight = TypeStyle.body(weight: .bold)
        let nonDynamic = TypeStyle.body(isDynamic: false)
        let callout = TypeStyle.body(isCallout: true)
        let custom = TypeStyle.body(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(body, TypeStyle(weight: .medium, size: 16, isDynamic: true, style: .body))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .bold, size: 16, isDynamic: true, style: .body))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .medium, size: 16, isDynamic: false, style: .body))
        XCTAssertEqual(callout, TypeStyle(weight: .medium, size: 16, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 16, isDynamic: false, style: .callout))
    }


     func testFootnote() {
        let footnote = TypeStyle.footnote()
        let modifiedWeight = TypeStyle.footnote(weight: .bold)
        let nonDynamic = TypeStyle.footnote(isDynamic: false)
        let callout = TypeStyle.footnote(isCallout: true)
        let custom = TypeStyle.footnote(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(footnote, TypeStyle(weight: .medium, size: 14, isDynamic: true, style: .footnote))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .bold, size: 14, isDynamic: true, style: .footnote))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .medium, size: 14, isDynamic: false, style: .footnote))
        XCTAssertEqual(callout, TypeStyle(weight: .medium, size: 14, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 14, isDynamic: false, style: .callout))
    }


     func testCaption() {
        let caption = TypeStyle.caption()
        let modifiedWeight = TypeStyle.caption(weight: .bold)
        let nonDynamic = TypeStyle.caption(isDynamic: false)
        let callout = TypeStyle.caption(isCallout: true)
        let custom = TypeStyle.caption(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(caption, TypeStyle(weight: .medium, size: 12, isDynamic: true, style: .caption1))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .bold, size: 12, isDynamic: true, style: .caption1))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .medium, size: 12, isDynamic: false, style: .caption1))
        XCTAssertEqual(callout, TypeStyle(weight: .medium, size: 12, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 12, isDynamic: false, style: .callout))
    }

     func testSmall() {
        let small = TypeStyle.small()
        let modifiedWeight = TypeStyle.small(weight: .medium)
        let nonDynamic = TypeStyle.small(isDynamic: false)
        let callout = TypeStyle.small(isCallout: true)
        let custom = TypeStyle.small(weight: .demiBold, isDynamic: false, isCallout: true)
        
        XCTAssertEqual(small, TypeStyle(weight: .bold, size: 10, isDynamic: true, style: .caption2))
        XCTAssertEqual(modifiedWeight, TypeStyle(weight: .medium, size: 10, isDynamic: true, style: .caption2))
        XCTAssertEqual(nonDynamic, TypeStyle(weight: .bold, size: 10, isDynamic: false, style: .caption2))
        XCTAssertEqual(callout, TypeStyle(weight: .bold, size: 10, isDynamic: true, style: .callout))
        XCTAssertEqual(custom, TypeStyle(weight: .demiBold, size: 10, isDynamic: false, style: .callout))
    }
}
