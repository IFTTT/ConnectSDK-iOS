//
//  Library.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

enum LibraryAccess: CustomDebugStringConvertible {
    case denied, restricted, notDetermined, authorized
    
    var canBeAuthorized: Bool {
        switch self {
        case .denied, .restricted: return false
        default: return true
        }
    }
    
    var debugDescription: String {
        switch self {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        }
    }
}

protocol Library {
    /// Maps the access authorization status of this native library to the `LibraryAccess` generalized type
    var access: LibraryAccess { get }
    
    /// Checks current access to this native library. If it's `notDetermined` then it requests access immediately.
    ///
    /// - Parameter completion: This will be called immediately if `access != .notDetermined` else it will prompt the user for access.
    func requestAccess(_ completion: @escaping (LibraryAccess) -> Void)
}
