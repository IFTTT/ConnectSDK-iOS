//
//  Notification.Name+Redirect.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    /// A `Notification.Name` used to post notifications when the app recieves a redirect request for a `Connection` activation.
    static let connectionRedirect = Notification.Name("ifttt.connection.redirect")
}
