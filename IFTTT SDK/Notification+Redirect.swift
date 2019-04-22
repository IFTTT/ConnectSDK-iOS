//
//  Notification.Name+Redirect.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

// FIXME: Not public

import Foundation

extension Notification.Name {
    
    /// A `Notification.Name` used to post notifications when the app recieves a redirect request for a `Connection` activation.
    static let authorizationRedirect = Notification.Name("ifttt.authorization.redirect")
}
