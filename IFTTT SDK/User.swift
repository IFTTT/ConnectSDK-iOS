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
}

extension String {
    private static let emailRegex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}",
                                                             options: [.caseInsensitive])
    
    var isValidEmail: Bool {
        return String.emailRegex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) > 0
    }
}
