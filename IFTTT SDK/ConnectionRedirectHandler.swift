//
//  ConnectionRedirectHandler.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// A class to handle redirections of `URL`s recieved as a part of the `Connection` activation process.
public final class ConnectionRedirectHandler {
    
    private let redirectURL: URL
    
    /// An `AuthenticationRedirectHandler` configured to handle a `URL`.
    ///
    /// - Parameter redirectURL: A `URL` that is used as the redirect sent on `Connection` activation.
    public init(redirectURL: URL) {
        self.redirectURL = redirectURL
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
        
        // Checks if the scheme matches the SDK redirect.
        if url.scheme == redirectURL.scheme {
            NotificationCenter.default.post(name: .connectionRedirect, object: url)
            return true
        }
        
        return false
    }
}
