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
    
    /// The `URL` that is used for authentication redirects.
    public let connectAuthorizationRedirectURL: URL
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connection: The `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - connectAuthorizationRedirectURL: The `URL` that is used for authentication redirects.
    public init(connection: Connection, suggestedUserEmail: String, credentialProvider: CredentialProvider, connectAuthorizationRedirectURL: URL) {
        self.connection = connection
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = credentialProvider
        self.connectAuthorizationRedirectURL = connectAuthorizationRedirectURL

    }
}
