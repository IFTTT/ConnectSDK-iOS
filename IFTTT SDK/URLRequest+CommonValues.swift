//
//  URLRequest+CommonValues.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension URLRequest {
    
    struct HeaderFields {
        static let inviteCode = "IFTTT-Invite-Code"
        static let sdkVersion = "IFTTT-SDK-Version"
        static let sdkPlatform = "IFTTT-SDK-Platform"
        static let sdkAnonymousId = "IFTTT-SDK-Anonymous-Id"
    }
    
    mutating func addIftttServiceToken(_ token: String) {
        let tokenString = "Bearer \(token)"
        addValue(tokenString, forHTTPHeaderField: "Authorization")
    }
    
    mutating func addIftttInviteCode(_ code: String) {
        addValue(code, forHTTPHeaderField: HeaderFields.inviteCode)
    }
    
    mutating func addVersionTracking() {
        setValue(API.sdkVersion, forHTTPHeaderField: HeaderFields.sdkVersion)
        setValue(API.sdkPlatform, forHTTPHeaderField: HeaderFields.sdkPlatform)
        setValue(API.anonymousId, forHTTPHeaderField: HeaderFields.sdkAnonymousId)
    }
}
