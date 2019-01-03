//
//  Settings.swift
//  SDK Example
//
//  Created by Jon Chmura on 1/2/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import IFTTT_SDK

/// Access current app settings
struct Settings {
    
    /// The current grocery express user email
    var email: String
    
    /// Signals that we should always use the new user connection flow
    var forcesNewUserFlow: Bool
    
    /// The style of the Connect Button (light / dark)
    var connectButtonStyle: ConnectButton.Style
    
    /// Gets the current settings
    init() {
        let defaults = UserDefaults.standard
        
        if let settings = defaults.dictionary(forKey: Keys.settings) {
            email = settings[Keys.email] as? String ?? ""
            forcesNewUserFlow = settings[Keys.forcesNewUserFlow] as? Bool ?? false
            if settings[Keys.isDarkStyle] as? Bool == true {
                connectButtonStyle = .dark
            } else {
                connectButtonStyle = .light
            }
        } else {
            email = ""
            forcesNewUserFlow = false
            connectButtonStyle = .light
        }
    }
    
    /// Saves these settings to disk
    func save() {
        let settings: [String : Any] = [
            Keys.email : email,
            Keys.forcesNewUserFlow : forcesNewUserFlow,
            Keys.isDarkStyle : connectButtonStyle == .dark
        ]
        UserDefaults.standard.set(settings, forKey: Keys.settings)
    }
    
    private struct Keys {
        static let settings = "settings"
        static let email = "email"
        static let forcesNewUserFlow = "forces_new_user_flow"
        static let isDarkStyle = "is_dark_style"
    }
}
