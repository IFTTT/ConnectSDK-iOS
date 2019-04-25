//
//  DeepLink.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 4/25/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

enum DeepLink {
    case connection(Connection)
    
    var url: URL {
        switch self {
        case .connection(let connection):
            return connection.url
        }
    }
    
    static var isIftttAppAvailable: Bool {
        return UIApplication.shared.canOpenURL(URL(string: API.iftttAppScheme)!)
    }
}
