//
//  AuthenticationSession.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import SafariServices
import AuthenticationServices

/// Wrapper for ASWebAuthenticationSession and SFAuthenticationSession types
@available(iOS 11.0, *)
final class AuthenticationSession {
    
    /// Creates a `AuthenticationSession`
    ///
    /// - Parameters:
    ///   - url: The url for an OAuth page
    ///   - callbackURLScheme: The URL scheme used in the redirect or nil. If passing nil, the scheme must be defined in the app's plist.
    ///   - completionHandler: Called when authentication finishes. Returns the Result.
    init(url: URL, callbackURLScheme: String? , completionHandler: @escaping (Result<URL, AuthenticationError>) -> Void) {
        let sessionCompletionHandler = { (url: URL?, error: Error?) -> Void in
            guard error == nil, let url = url else {
                completionHandler(.failure(.userCanceled))
                return
            }
            completionHandler(.success(url))
        }
        
        if #available(iOS 12, *) {
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: sessionCompletionHandler)
            session = .webAuthSession(authSession)
        } else {
            let authSession = SFAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: sessionCompletionHandler)
            session = .safariAuthSession(authSession)
        }
    }
    
    /// Begin the authentication session
    /// This will prompt the user for permission and present Safari
    ///
    /// - Returns: True is successful
    @discardableResult func start() -> Bool {
        switch session {
        case .webAuthSession(let authSession):
            return authSession.start()
        case .safariAuthSession(let authSession):
            return authSession.start()
        }
    }
    
    /// Cancels the current authentication session and dismisses Safari
    func cancel() {
        switch session {
        case .webAuthSession(let authSession):
            return authSession.cancel()
        case .safariAuthSession(let authSession):
            return authSession.cancel()
        }
    }
    
    /// Describes the error reason for a failed `AuthenticationSession`
    ///
    /// - userCanceled: The user Cancelled the authentication session
    enum AuthenticationError: Error {
        case userCanceled
    }
    
    /// We must hold a reference to the authentication session so it is not deallocated
    /// This differs from a safari view controller because it is not referenced in the parent view controllers heirarchy
    private let session: Session
    
    /// Wraps API differences between iOS 11 and 12
    private enum Session {
        @available(iOS 12.0, *)
        case webAuthSession(ASWebAuthenticationSession)
        
        case safariAuthSession(SFAuthenticationSession)
    }
}
