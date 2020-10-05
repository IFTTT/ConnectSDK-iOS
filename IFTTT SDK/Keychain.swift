//
//  Keychain.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

final class Keychain {
    enum Key: String, CaseIterable {
        case UserToken = "KeychainKey.IFTTTUserToken"
        case InviteCode = "KeychainKey.PlatformInviteCode"
    }
    
    static var userToken: String? {
        get {
            getValue(for: .UserToken)
        }
        set {
            set(value: newValue, for: .UserToken)
        }
    }
    
    static var inviteCode: String? {
        get {
            getValue(for: .InviteCode)
        }
        set {
            set(value: newValue, for: .InviteCode)
        }
    }

    private class func set(value: String?, for key: Key) {
        guard let value = value else {
            removeValue(for: key)
            return
        }
        guard let valueData = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: valueData
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private class func getValue(for key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == noErr else { return nil }
        
        guard let data = dataTypeRef as? Data else { return nil }
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        
        return string
    }


    private class func removeValue(for key: Key) {
        // Only remove the value for the key if it exists in the keychain
        if getValue(for: key) == nil { return }
            
        // Instantiate a new default keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        // Delete any existing items
        let status = SecItemDelete(query as CFDictionary)
        
        if (status != errSecSuccess) {
            if #available(iOS 11.3, *) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    debugPrint("Keychain Remove failed: \(err)")
                }
            }
        }
    }
    
    private class func reset() {
        Key.AllCases().forEach {
            removeValue(for: $0)
        }
    }
    
    class func resetIfNecessary(force: Bool) {
        if UserDefaults.anonymousId == nil || force {
            Keychain.reset()
        }
    }
}
