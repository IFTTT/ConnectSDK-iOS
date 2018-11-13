//
//  API.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct API {
    
    private struct URLConstants {
        static let base = "https://api.ifttt.com/v2"
        static let findEmail = "/account/find?email="
        static let me = "/me"
    }

    static let base = URL(string: API.URLConstants.base)!
    
    static func findUserBy(email: String) -> URL {
        return URL(string: "\(API.URLConstants.base)\(API.URLConstants.findEmail)\(email)")!
    }
    
    static let findUserByToken = URL(string: "\(API.URLConstants.base)\(API.URLConstants.me)")!
}
