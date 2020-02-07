//
//  API.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

struct API {
    
    static let iftttAppScheme = "ifttt-handoff-v1://"
    
    /// The unique id for IFTTT's App Store listing
    static let iftttAppStoreId = "660944635"
    
    static let sdkVersion = Bundle.sdk.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    static let sdkPlatform = "ios"
    static let osVersion = UIDevice.current.systemVersion
    
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
        static let base = "https://connect.ifttt.com/v2"
        static let findEmail = "/account/find"
        static let emailName = "email"
        static let me = "/me"
        static let analytics = "/sdk/events"
    }

    static let base = URL(string: API.URLConstants.base)!
    static let findEmail = URL(string: "\(API.URLConstants.base)\(API.URLConstants.findEmail)")!
    
    static func findUserBy(email: String) -> URL? {
        var components = URLComponents(url: API.findEmail, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: API.URLConstants.emailName, value: email)]
        return components?.fixingEmailEncoding().url
    }
    
    static let findUserByToken = URL(string: "\(API.URLConstants.base)\(API.URLConstants.me)")!
    static let submitAnalytics = URL(string: "\(API.URLConstants.base)\(API.URLConstants.analytics)")!
    
    private struct Keys {
        static let anonymousIdKey = "com.ifttt.sdk.analytics.anonymous_id"
    }
}
