//
//  API.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct API {
    
    /// The unique id for IFTTT's App Store listing
    static let iftttAppStoreId = "660944635"
    
    static let sdkVersion = "2.0.0-alpha4"
    static let sdkPlatform = "ios"
    
    private struct URLConstants {
        static let base = "https://api.ifttt.com/v2"
        static let findEmail = "/account/find?email="
        static let me = "/me"
    }

    static let base = URL(string: API.URLConstants.base)!
    
    static func findUserBy(email: String) -> URL {
        return URL(string: "\(API.URLConstants.base)\(API.URLConstants.findEmail)\(email)")!
    }
    
    static let findUserByToken = URL(string: "\(API.URLConstants.base)\(API.URLConstants.me)")!
}
