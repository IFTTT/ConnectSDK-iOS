//
//  ConnectionCredentials.swift
//  SDK Example
//
//  Created by Jon Chmura on 1/3/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import IFTTT_SDK

/// Provides the user's credentials related to IFTTT Connections
class ConnectionCredentials: CredentialProvider, CustomStringConvertible {
    
    /// The email address for the connected IFTTT account
    let email: String
    
    /// The OAuth code of the Grocery Express service, used to automatically connect Grocery Express to IFTTT during a Connection flow.
    var partnerOAuthCode: String {
        /// The Grocery Express service doesn't use real OAuth codes since it is only for demoing
        /// It will accept any value for an OAuth code, send the IFTTT email address for simplicity
        /// In your app, you should send a real value here
        return email
    }
    
    /// The IFTTT access token for this user, related to the Grocery Express service
    /// This token permits you to access the user's Connections for Grocery Express but not for any other services on IFTTT
    /// This is also the token that you use to make requests to the Connection API for triggers, actions, and queries on the user's behalf
    private(set) var iftttServiceToken: String?
    
    /// Grocery Express is an unpublished service, therefore we must provide the invite code from https://platform.ifttt.com/services/grocery_express/general
    /// If your service is in development, you will find your invite code here
    var inviteCode: String? {
        return "213621-90a10d229fbf8177a7ba0e6249847daf"
    }
    
    /// Have we made a successful IFTTT Connection
    var isLoggedIn: Bool {
        return iftttServiceToken != nil
    }
    
    /// Prints the IFTTT email and token for debugging purposes
    var description: String {
        if let token = iftttServiceToken {
            return "Email: \(email)\nToken: \(token)"
        } else {
            return "Logged out"
        }
    }
    
    /// After making a Connection, store the IFTTT service token
    /// In a real app, this should be kept in a secure location
    ///
    /// - Parameter token: The IFTTT service token
    func loginUser(with token: String) {
        iftttServiceToken = token
        let user: [String : Any] = [
            Keys.email : email,
            Keys.token : token
        ]
        UserDefaults.standard.set(user, forKey: Keys.user)
    }
    
    /// Attemps to get the IFTTT service token
    /// Login attemp will fail if the user hasn't made a Connection with Grocery Express
    /// Returns immediately if the user is already logged in
    ///
    /// - Parameter completion: Returns the updated ConnectionCredentials
    static func attempLogin(_ completion: ((ConnectionCredentials) -> Void)? = nil) {
        // Attempt to get the IFTTT service token if we don't already have one.
        let credentials = ConnectionCredentials(settings: Settings())
        if credentials.iftttServiceToken == nil {
            TokenRequest.getIFTTTServiceToken(for: credentials.email) { (token) in
                if let token = token {
                    credentials.loginUser(with: token)
                }
                completion?(credentials)
            }
        } else {
            completion?(credentials)
        }
    }
    
    /// Clears the active IFTTT session
    func logout() {
        iftttServiceToken = nil
        UserDefaults.standard.set(nil, forKey: Keys.user)
    }
    
    /// Creates an instance of ConnectionCredentials
    ///
    /// - Parameter settings: If there is not a logged in user, generate credentials based on the current Grocery Express user
    init(settings: Settings) {
        if let user = UserDefaults.standard.dictionary(forKey: Keys.user), let email = user[Keys.email] as? String, let token = user[Keys.token] as? String {
            self.email = email
            self.iftttServiceToken = token
        } else {
            if settings.forcesNewUserFlow, let atIndex = settings.email.firstIndex(where: { $0 == "@" }) {
                var newUserEmail = settings.email
                newUserEmail.insert(contentsOf: "+\(Date().timeIntervalSince1970)", at: atIndex)
                self.email = newUserEmail
            } else {
                self.email = settings.email
            }
            iftttServiceToken = nil
        }
    }
    
    private struct Keys {
        static let user = "ifttt_user"
        static let email = "email"
        static let token = "token"
    }
}
