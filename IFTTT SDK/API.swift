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
    
    static let sdkVersion = "2.0.0-alpha5"
    static let sdkPlatform = "ios"
    
    /// An installation id for this instance of the SDK. This id remains static from installation to deletion of the partner app.
    static var anonymousId: String {
        if let id = UserDefaults.standard.string(forKey: Keys.anonymousIdKey) {
            return id
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: Keys.anonymousIdKey)
            return id
        }
    }
    
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
    
    private struct Keys {
        static let anonymousIdKey = "com.ifttt.sdk.analytics.anonymous_id"
    }
}
