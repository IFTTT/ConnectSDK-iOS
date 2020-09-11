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
        if let id = UserDefaults.anonymousId {
            return id
        } else {
            let id = UUID().uuidString
            UserDefaults.anonymousId = id
            return id
        }
    }
    
    private struct URLConstants {
        static let base = "https://connect.ifttt.com/v2"
        static let locationBase = "https://connectapi.ifttt.com/v1"
        static let findEmail = "/account/find"
        static let emailName = "email"
        static let me = "/me"
        static let analytics = "/sdk/events"
    }

    static let base = URL(string: API.URLConstants.base)!
    static let locationBase = URL(string: API.URLConstants.locationBase)!
    static let findEmail = URL(string: "\(API.URLConstants.base)\(API.URLConstants.findEmail)")!
    
    static func findUserBy(email: String) -> URL? {
        var components = URLComponents(url: API.findEmail, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: API.URLConstants.emailName, value: email)]
        return components?.fixingEmailEncoding().url
    }
    
    static let findUserByToken = URL(string: "\(API.URLConstants.base)\(API.URLConstants.me)")!
    static let submitAnalytics = URL(string: "\(API.URLConstants.base)\(API.URLConstants.analytics)")!
}

/// Helper accessors for `UserDefaults`
extension UserDefaults {
    private struct Keys {
        static let anonymousId = "com.ifttt.sdk.analytics.anonymous_id"
        static let shouldHideFooterUserDefaults = "appShouldHideConnectButtonFooter"
        static let QueueUserDefaults = "ifttt_sdk.analytics.queued_events.key"
        static let ConnectionsRegistry = "ConnectionsRegistry.ConnectionsUserDefaultKey"
        static let RegionEventsRegistry = "RegionEventsRegistry.Key"
    }
    
    static var anonymousId: String? {
        get {
            return standard.string(forKey: Keys.anonymousId)
        }
        set {
            guard let newValue = newValue else {
                standard.removeObject(forKey: Keys.anonymousId)
                return
            }
            standard.set(newValue, forKey: Keys.anonymousId)
        }
    }
    
    /// Used by an app to determine if it should hide the footer on the Connect Button.
    static var shouldHideFooter: Bool {
        get {
            return standard.bool(forKey: Keys.shouldHideFooterUserDefaults)
        }
        set {
            standard.set(newValue, forKey: Keys.shouldHideFooterUserDefaults)
        }
    }
    
    static var analyticsQueue: [AnalyticsData]? {
        get {
            return UserDefaults.standard.array(forKey: Keys.QueueUserDefaults) as? [AnalyticsData]
        }
        set {
            guard let newValue = newValue else {
                standard.removeObject(forKey: Keys.QueueUserDefaults)
                return
            }
            standard.set(newValue, forKey: Keys.QueueUserDefaults)
        }
    }
    
    static var connections: [String: Any]? {
        get {
            return UserDefaults.standard.dictionary(forKey: Keys.ConnectionsRegistry)
        }
        set {
            guard let newValue = newValue else {
                standard.removeObject(forKey: Keys.ConnectionsRegistry)
                return
            }
            standard.set(newValue, forKey: Keys.ConnectionsRegistry)
        }
    }
    
    static var regionEvents: [Any]? {
        get {
            return UserDefaults.standard.array(forKey: Keys.RegionEventsRegistry)
        }
        set {
            guard let newValue = newValue else {
                standard.removeObject(forKey: Keys.RegionEventsRegistry)
                return
            }
            standard.set(newValue, forKey: Keys.RegionEventsRegistry)
        }
    }
}
