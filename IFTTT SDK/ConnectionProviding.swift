//
//  ConnectionProviding.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A protocol that defines APIs for providing tokens used during the service connection process for an Applet.
public protocol ConnectionProviding {
    
    /// A `URL` used as the activation redirection endpoint.
    var activationRedirect: URL { get }
    
    /// Provides the service's token associated with the IFTTT platform.
    var inviteCode: String? { get }
}
