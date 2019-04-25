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
    /// This code is used to automatically connect your service to IFTTT for the current user when they enable a Connection. This is important so the user is not prompted to sign into your service which would be a poor UX.
    var oauthCode: String { get }
    
    /// Provides the user token for the IFTTT user account.
    /// This is the same token used with the Connection API.
    /// The IFTTT user token can be obtained on your backend via server to server communication with IFTTT using your IFTTT service key if the user has already connected your service.
    /// Also, the callback from ConnectButtonController returns the user token when a connection is made.
    var userToken: String? { get }
    
    /// Provides the invite code for testing an unpublished service. If you are developing a service which hasn't been published you can find the invite on code platform.ifttt.com. If your service is published, return nil.
    var inviteCode: String? { get }
}
