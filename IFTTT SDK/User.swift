//
//  User.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public struct User {
    enum ID {
        case id(String), email(String)
    }
    
    public static var current = User()
    
    public var suggestedUserEmail: String?
}
