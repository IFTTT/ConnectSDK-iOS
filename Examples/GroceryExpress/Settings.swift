//
//  Settings.swift
//  SDK Example
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import IFTTTConnectSDK

/// Access current app settings
struct Settings {
    
    /// The current grocery express user email
    var email: String
    
    /// Signals that we should always use the new user connection flow
    var forcesNewUserFlow: Bool
    
    /// Signals that we should always use the connection fetching flow
    var fetchConnectionFlow: Bool
    
    /// Gets the current settings
    init() {
        let defaults = UserDefaults.standard
        
        if let settings = defaults.dictionary(forKey: Keys.settings) {
            email = settings[Keys.email] as? String ?? ""
            forcesNewUserFlow = settings[Keys.forcesNewUserFlow] as? Bool ?? false
            fetchConnectionFlow = settings[Keys.fetchConnectionFlow] as? Bool ?? false
        } else {
            email = ""
            forcesNewUserFlow = false
            fetchConnectionFlow = false
        }
    }
    
    /// Saves these settings to disk
    func save() {
        let settings: [String : Any] = [
            Keys.email : email,
            Keys.forcesNewUserFlow : forcesNewUserFlow,
            Keys.fetchConnectionFlow : fetchConnectionFlow,
        ]
        UserDefaults.standard.set(settings, forKey: Keys.settings)
    }
    
    private struct Keys {
        static let settings = "settings"
        static let email = "email"
        static let forcesNewUserFlow = "forces_new_user_flow"
        static let fetchConnectionFlow = "fetch_connection_flow"
        static let isDarkStyle = "is_dark_style"
    }
}
