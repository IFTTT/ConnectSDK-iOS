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
    
    /// The `Connection` for authentication.
    public let connection: Connection
    
    /// A `String` provided as the suggested user's email address.
    public let suggestedUserEmail: String
    
    /// A `CredentialProvider` conforming object for providing credentials.
    public let credentialProvider: CredentialProvider
    
    /// A `URL` used as the activation redirection endpoint.
    public let connectionRedirectURL: URL
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connection: The `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` provided as the suggested user's email address.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - connectionRedirectURL: The `URL` that is used for authentication redirects endpoint.
    public init(connection: Connection, suggestedUserEmail: String, tokenProvider: CredentialProvider, connectionRedirectURL: URL) {
        self.connection = connection
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = tokenProvider
        self.connectionRedirectURL = connectionRedirectURL
    }
}
