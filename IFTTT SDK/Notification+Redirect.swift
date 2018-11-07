//
//  Notification.Name+Redirect.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    /// A `Notification.Name` used to post notifications when the app recieves a redirect request for an `Applet` activation.
    static let appletActivationRedirect = Notification.Name("ifttt.applet.activation.redirect")
}
