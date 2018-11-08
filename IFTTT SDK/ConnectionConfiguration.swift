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
    
    // An object that handle providing common information for a session.
    public let connectionProvider: ConnectionProviding
    
    /// An object that handle providing tokens for a session.
    public let tokenProvider: TokenProviding
    
    /// A `String` provided as the suggested user's email address.
    public let suggestedUserEmail: String
    
    public init(applet: Applet, connectionProvider: ConnectionProviding, tokenProvider: TokenProviding, suggestedUserEmail: String) {
        self.applet = applet
        self.connectionProvider = connectionProvider
        self.tokenProvider = tokenProvider
        self.suggestedUserEmail = suggestedUserEmail
    }
}
