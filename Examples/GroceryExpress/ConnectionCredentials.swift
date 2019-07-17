//
//  ConnectionCredentials.swift
//  SDK Example
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import IFTTTConnectSDK

/// Provides the user's credentials related to IFTTT Connections
class ConnectionCredentials: ConnectionCredentialProvider, CustomStringConvertible {
    
    /// The email address for the connected IFTTT account
    let email: String
    
    /// The OAuth code of the Grocery Express service, used to automatically connect Grocery Express to IFTTT during a Connection flow.
    var oauthCode: String {
        /// The Grocery Express service doesn't use real OAuth codes since it is only for demoing
        /// It will accept any value for an OAuth code, send the IFTTT email address for simplicity
        /// In your app, you should send a real value here
        return email
    }
    
    /// The IFTTT access token for this user, related to the Grocery Express service
    /// This token permits you to access the user's Connections for Grocery Express but not for any other services on IFTTT
    /// This is also the token that you use to make requests to the Connection API for triggers, actions, and queries on the user's behalf
    private(set) var userToken: String?
    
    /// This is required if your service is in development and has not been published. Check the platform to get this code. See SDK readme for more details. 
    var inviteCode: String? {
        return nil
    }
    
    /// Have we made a successful IFTTT Connection
    var isLoggedIn: Bool {
        return userToken != nil
    }
    
    /// Prints the IFTTT email and token for debugging purposes
    var description: String {
        if let token = userToken {
            return "Email: \(email)\nToken: \(token)"
        } else {
            return "Logged out"
        }
    }
    
    /// After making a Connection, store the IFTTT service token
    /// In a real app, this should be kept in a secure location
    /// See `ConnectionCredentials.requestToken`
    ///
    /// - Parameter token: The IFTTT service token
    func loginUser(with token: String) {
        userToken = token
        let user: [String : Any] = [
            Keys.email : email,
            Keys.token : token
        ]
        UserDefaults.standard.set(user, forKey: Keys.user)
    }
    
    /// Clears the active IFTTT session
    func logout() {
        userToken = nil
        UserDefaults.standard.set(nil, forKey: Keys.user)
    }
    
    /// Creates an instance of ConnectionCredentials
    ///
    /// - Parameter settings: If there is not a logged in user, generate credentials based on the current Grocery Express user
    init(settings: Settings) {
        if let user = UserDefaults.standard.dictionary(forKey: Keys.user), let email = user[Keys.email] as? String, let token = user[Keys.token] as? String {
            self.email = email
            self.userToken = token
        } else {
            if settings.forcesNewUserFlow, let atIndex = settings.email.firstIndex(where: { $0 == "@" }) {
                var newUserEmail = settings.email
                newUserEmail.insert(contentsOf: "+\(Date().timeIntervalSince1970)", at: atIndex)
                self.email = newUserEmail
            } else {
                self.email = settings.email
            }
            userToken = nil
        }
    }
    
    private struct Keys {
        static let user = "ifttt_user"
        static let email = "email"
        static let token = "token"
    }
}
