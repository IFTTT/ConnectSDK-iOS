//
//  ConnectionConfiguration.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
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
    public let credentialProvider: ConnectionCredentialProvider
    
    /// The `URL` that is used for authentication redirects.
    public let redirectURL: URL
    
    /// An flag that allows users to skip configuration of the connection when it's activated either in the IFTTT app or the web flow
    public let skipConnectionConfiguration: Bool
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connectionId: The connection identifier to fetch the `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - redirectURL: The `URL` that is used for connection activation redirects.
    ///   - skipConnectionConfiguration: A `Bool` that is used to skip the configuration of the Connection when it's activated in either the IFTTT app or the web flow. Defaults to `false`.
    public init(connectionId: String,
                suggestedUserEmail: String,
                credentialProvider: ConnectionCredentialProvider,
                redirectURL: URL,
                skipConnectionConfiguration: Bool = false) {
        self.connectionId = connectionId
        self.connection = nil
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = credentialProvider
        self.redirectURL = redirectURL
        self.skipConnectionConfiguration = skipConnectionConfiguration
    }
    
    /// Creates a new `ConnectionConfiguration`.
    ///
    /// - Parameters:
    ///   - connection: The `Connection` for authentication.
    ///   - suggestedUserEmail: A `String` with a an email for the user.
    ///   - credentialProvider: A `CredentialProvider` conforming object for providing credentials.
    ///   - redirectURL: The `URL` that is used for connection activation redirects.
    ///   - skipConnectionConfiguration: A `Bool` that is used to skip the configuration of the Connection when it's activated in either the IFTTT app or the web flow. Defaults to `false`.
    public init(connection: Connection,
                suggestedUserEmail: String,
                credentialProvider: ConnectionCredentialProvider,
                redirectURL: URL,
                skipConnectionConfiguration: Bool = false) {
        self.connectionId = connection.id
        self.connection = connection
        self.suggestedUserEmail = suggestedUserEmail
        self.credentialProvider = credentialProvider
        self.redirectURL = redirectURL
        self.skipConnectionConfiguration = skipConnectionConfiguration
    }
}
