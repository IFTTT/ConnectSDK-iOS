//
//  URLRequest+CommonValues.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension URLRequest {
    
    mutating func addIftttUserToken(_ token: String) {
        let tokenString = "Bearer \(token)"
        addValue(tokenString, forHTTPHeaderField: "Authorization")
    }
    
    mutating func addIftttInviteCode(_ code: String) {
        addValue(code, forHTTPHeaderField: "IFTTT-Invite-Code")
    }
}
