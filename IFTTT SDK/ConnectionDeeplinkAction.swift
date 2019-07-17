//
//  ConnectionDeeplinkAction.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

enum ConnectionDeeplinkAction: String {
    case view = "view"
    case edit = "edit"
    case activation = "activation"
    
    static var isIftttAppAvailable: Bool {
        return UIApplication.shared.canOpenURL(URL(string: API.iftttAppScheme)!)
    }
}

