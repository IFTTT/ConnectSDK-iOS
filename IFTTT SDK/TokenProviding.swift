//
//  TokenProviding.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A protocol that defines APIs for requesting tokens for services.
public protocol TokenProviding {
    
    var partnerOAuthToken: String? { get }
    
    var iftttServiceToken: String? { get }
    
//    /// Provides the partner OAuth token for the provided session.
//    ///
//    /// - Parameter session: The `Applet.Session` that the partner OAuth token is for.
//    /// - Returns: A `String` that respresents the OAuth token for the partner's connection service.
//    func partnerOauthTokenForServiceConnection(_ session: Applet.Session) -> String
//    
//    /// Provides the IFTTT user token for the provided session.
//    ///
//    /// - Parameter session: The `Applet.Session` that the IFTTT user token is for.
//    /// - Returns: A `String` that respresents the IFTTT user token for the connection service.
//    func iftttUserToken(for session: Applet.Session) -> String?
}
