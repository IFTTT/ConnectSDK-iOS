//
//  AuthenticationRedirectHandler.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A class to handle redirections of `URL`s recieved as a part of the `Connection` activation process.
public final class AuthenticationRedirectHandler {
    
    private let authorizationRedirectURL: URL
    
    /// An `AuthenticationRedirectHandler` configured to handle a `URL`.
    ///
    /// - Parameter authorizationRedirectURL: A `URL` that is used as the redirect sent on `Connection` activation.
    public init(authorizationRedirectURL: URL) {
        self.authorizationRedirectURL = authorizationRedirectURL
    }
    
    /// Handles redirects during a `Connection` activation.
    ///
    /// Generally, this is used to handle url redirects the app recieves in `func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool` in the `AppDelgate`.
    /// - Example: `AuthenticationRedirectHandler.handleApplicationRedirect(url: url, options: options)`.
    ///
    /// - Parameters:
    ///   - url: The `URL` resource to open.
    ///   - options: A dictionary of `URL` handling options. For information about the possible keys in this dictionary, see UIApplicationOpenURLOptionsKey.
    /// - Returns: True if this is an IFTTT SDK redirect. False for any other `URL`.
    public func handleApplicationRedirect(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        
        // Checks if the source is `SafariViewService` and the scheme matches the SDK redirect.
        if let source = options[.sourceApplication] as? String, url.scheme == authorizationRedirectURL.scheme && source == "com.apple.SafariViewService" {
            NotificationCenter.default.post(name: .authorizationRedirect, object: url)
            return true
        }
        
        return false
    }
}
