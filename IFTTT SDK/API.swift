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
        static let findEmail = "/account/find"
        static let emailName = "email"
        static let me = "/me"
    }

    static let base = URL(string: API.URLConstants.base)!
    static let findEmail = URL(string: "\(API.URLConstants.base)\(API.URLConstants.findEmail)")!
    
    static func findUserBy(email: String) -> URL? {
        var components = URLComponents(url: API.findEmail, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [URLQueryItem(name: API.URLConstants.emailName, value: email)]
        
        // We need to manually encode `+` characters in a user's e-mail because `+` is a valid character that represents a space in a url query. E-mail's with spaces are not valid.
        let percentEncodedQuery = components?.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: .emailEncodingPassthrough)
        components?.percentEncodedQuery = percentEncodedQuery
        
        return components?.url
    }
    
    static let findUserByToken = URL(string: "\(API.URLConstants.base)\(API.URLConstants.me)")!
    
    private struct Keys {
        static let anonymousIdKey = "com.ifttt.sdk.analytics.anonymous_id"
    }
}
