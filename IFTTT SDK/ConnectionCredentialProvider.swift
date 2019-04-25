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
    
    /// The OAuth code for your user on your service. This is used to skip a step for connecting to your own service during the Connect Button activation flow. We require this value to provide the best possible user experience.
    var oauthCode: String { get }
    
    /// This is the IFTTT user token for your service. This token allows you to get IFTTT user data related to only your service. For example, include this token to get the enabled status of Connections for your user. It is also the same token that is used to make trigger, query, and action requests for Connections on behave of the user. You should get this token from a communication between your servers and ours using your `IFTTT-Service-Key`. Never include this key in your app binary, rather create on endpoint on your own server to access the user's IFTTT service token.
    /// Additionally, the callback from ConnectButtonController returns the user token when a connection is made.
    /// You should support both method, in the case that your user has already connected your service to IFTTT.
    var userToken: String? { get }
    
    /// This value is only required if your service is not published. You can find it on https://platform.ifttt.com on the Service tab in General under invite URL. If your service is published, return nil.
    var inviteCode: String? { get }
}
