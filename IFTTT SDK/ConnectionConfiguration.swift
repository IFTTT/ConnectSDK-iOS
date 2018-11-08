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
    
    /// A `URL` used as the activation redirection endpoint.
    public let activationRedirect: URL
    
    /// An optional `String` containing an invitation code for the session.
    public let inviteCode: String?
    
    public init(applet: Applet, suggestedUserEmail: String, activationRedirect: URL, inviteCode: String?) {
        self.applet = applet
        self.suggestedUserEmail = suggestedUserEmail
        self.activationRedirect = activationRedirect
        self.inviteCode = inviteCode
    }
}
