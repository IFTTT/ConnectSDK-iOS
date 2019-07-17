//
//  User.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

struct User {
    enum Id {
        case username(String), email(String)
        
        var value: String {
            switch self {
            case .username(let username):
                return username
            case .email(let email):
                return email
            }
        }
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
    
    /// Checks whether a string contains a e-mail address.
    ///
    /// - Returns: A `Bool` on whether a e-mail address is present.
    /// - Throws: If a `NSDataDetector` can not be created.
    var isValidEmail: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            
            // Returning true because the data detectored failed to initalized and we can not validate the e-mail. Erroring on the side of the e-mail being valid in this case.
            return true
        }
        
        let range = NSRange(location: 0, length: count)
        let matches = detector.matches(in: self, options: [], range: range)
        
        guard matches.count == 1, let result = matches.first, range == result.range else { return false }
        return result.url?.scheme == "mailto"
    }
}
