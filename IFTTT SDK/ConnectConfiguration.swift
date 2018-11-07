//
//  ConnectConfiguration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct ConnectConfiguration {
    
    enum UserLookupMethod {
        case token(String), email(String)
    }
    
    let isExistingUser: Bool
    let userId: User.Id
}
