//
//  ConnectionCredentialProvider.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A protocol that defines APIs for providing credentials used during the service authentication process for an `Connection`.
public protocol ConnectionCredentialProvider {
    
    /// Provides the OAuth code for your user.
    /// This code is used to automatically connect your service to IFTTT for the current user when the enable a Connection.
    var oauthCode: String { get }
    
    /// Provides the user token for the IFTTT user account.
    /// This is the same token used with the Connection API.
    var userToken: String? { get }
    
    /// Provides the invite code for testing an unpublished `Connection`'s services with the IFTTT platform.
    var inviteCode: String? { get }
}
