//
//  ConnectionConfiguration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public struct ConnectionConfiguration {
    
    /// The identifier of the `Connection`.
    public let applet: Applet
    
    /// A `String` provided as the suggested user's email address.
    public let suggestedUserEmail: String
    
    /// An object that handle providing tokens for a session.
    public let tokenProvider: TokenProviding
    
    /// A `URL` used as the activation redirection endpoint.
    public let connectActivationRedirectURL: URL
    
    public init(applet: Applet, suggestedUserEmail: String, tokenProvider: TokenProviding, connectActivationRedirectURL: URL) {
        self.applet = applet
        self.suggestedUserEmail = suggestedUserEmail
        self.tokenProvider = tokenProvider
        self.connectActivationRedirectURL = connectActivationRedirectURL
    }
}
