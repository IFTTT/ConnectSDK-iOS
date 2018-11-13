//
//  TokenProviding.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A protocol that defines APIs for providing tokens used during the service connection process for an Applet.
public protocol TokenProviding {
    
    /// Provides the partner's OAuth code for a service during Applet connection.
    var partnerOAuthCode: String { get }
    
    /// Provides the service's token associated with the IFTTT platform.
    var iftttServiceToken: String? { get }
}
