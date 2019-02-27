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
    
    /// The identifier for the `Connection`.
    public let connectionId: String
    
    /// The `Connection` for authentication.
    public let connection: Connection?
    
    /// A `String` provided as the suggested user's email address.
    public let suggestedUserEmail: String
    
    /// A `CredentialProvider` conforming object for providing credentials.
    public let credentialProvider: CredentialProvider
    
    /// The `URL` that is used for authentication redirects.
    public let connectAuthorizationRedirectURL: URL
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connectionId: The connection identifier to fetch the `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - connectAuthorizationRedirectURL: The `URL` that is used for authentication redirects.
    public init(connectionId: String, suggestedUserEmail: String, credentialProvider: CredentialProvider, connectAuthorizationRedirectURL: URL) {
        self.connectionId = connectionId
        self.connection = nil
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = credentialProvider
        self.connectAuthorizationRedirectURL = connectAuthorizationRedirectURL
    }
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connection: The `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - connectAuthorizationRedirectURL: The `URL` that is used for authentication redirects.
    public init(connection: Connection, suggestedUserEmail: String, credentialProvider: CredentialProvider, connectAuthorizationRedirectURL: URL) {
        self.connectionId = connection.id
        self.connection = connection
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = credentialProvider
        self.connectAuthorizationRedirectURL = connectAuthorizationRedirectURL
    }
}
