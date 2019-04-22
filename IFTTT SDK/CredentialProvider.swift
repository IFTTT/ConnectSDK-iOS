//
//  CredentialProvider.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

// FIXME: ConnectionCredentialProvider

/// A protocol that defines APIs for providing credentials used during the service authentication process for an `Connection`.
public protocol CredentialProvider {
    
    // FIXME: oauthCode
    /// Provides the partner's OAuth code for a service during authentication with a `Connection`.
    var partnerOAuthCode: String { get }
    
    // FIXME: userToken
    /// Provides the service's token associated with the IFTTT platform.
    var iftttServiceToken: String? { get }
    
    /// Provides the invite code for testing an unpublished `Connection`'s services with the IFTTT platform.
    var inviteCode: String? { get }
}
