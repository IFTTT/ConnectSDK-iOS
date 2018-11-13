//
//  ConnectionConfiguration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// Encapsulates the information needed to authenticate a `Connection`'s services.
public struct ConnectionConfiguration {
    
    /// The identifier of the `Connection`.
    public let connection: Connection
    
    /// A `String` provided as the suggested user's email address.
    public let suggestedUserEmail: String
    
    /// An object that handle providing tokens for a session.
    public let tokenProvider: CredentialProvider
    
    /// A `URL` used as the activation redirection endpoint.
    public let connectionRedirectURL: URL
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connection: The `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - tokenProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - connectionRedirectURL: The `URL` that is used for authentication redirects.
    public init(connection: Connection, suggestedUserEmail: String, tokenProvider: CredentialProvider, connectionRedirectURL: URL) {
        self.connection = connection
        self.suggestedUserEmail = suggestedUserEmail
        self.tokenProvider = tokenProvider
        self.connectionRedirectURL = connectionRedirectURL
    }
}
