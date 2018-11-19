//
//  User.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 10/29/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct User {
    enum Id {
        case username(String), email(String)
    }
    
    /// We know something about a user when they begin a connect button flow.
    /// This type tells the `ConnectionNetworkController` how to identify the user's IFTTT account.
    /// If we have a token, there must be an associate account. If we only have an email, they could be new to IFTTT.
    /// The `ConnectionNetworkController` resolves this to a `User` instance.
    ///
    /// - token: The user is already logged in to IFTTT and we have an IFTTT service user token
    /// - email: The user is not logged in but we know their email address
    enum LookupMethod {
        case token(String), email(String)
    }
    
    let id: User.Id
    let isExistingUser: Bool
}

extension String {
    private static let emailRegex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}",
                                                             options: [.caseInsensitive])
    
    var isValidEmail: Bool {
        return String.emailRegex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) > 0
    }
}
