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
    @available(iOS, deprecated: 13, obsoleted: 12, message: "API is deprecated in iOS 13 and obsoleted in iOS 12")
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
        
        authenticationSessionContextProvider = nil
    }
    
    /// Creates a `AuthenticationSession`
    ///
    /// - Parameters:
    ///   - url: The url for an OAuth page
    ///   - callbackURLScheme: The URL scheme used in the redirect or nil. If passing nil, the scheme must be defined in the app's plist.
    ///   - presentationContext: The `UIWindow` instance to use in presenting the web authentication flow.
    ///   - completionHandler: Called when authentication finishes. Returns the Result.
    @available(iOS 13.0, *)
    init(url: URL, callbackURLScheme: String?, presentationContext: UIWindow, completionHandler: @escaping (Result<URL, AuthenticationError>) -> Void) {
        let sessionCompletionHandler = { (url: URL?, error: Error?) -> Void in
            guard error == nil, let url = url else {
                completionHandler(.failure(.userCanceled))
                return
            }
            completionHandler(.success(url))
        }
        
        let authenticationSessionContextProvider = AuthenticationSessionContextProvider(presentationContext: presentationContext)
        let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: sessionCompletionHandler)
        authSession.presentationContextProvider = authenticationSessionContextProvider
        
        self.authenticationSessionContextProvider = authenticationSessionContextProvider
        self.session = .webAuthSession(authSession)
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
    
    /// We must hold a reference to the session context provider so it's not deallocated.
    /// Only used with `ASWebAuthenticationSession` in iOS 13 and up.
    private let authenticationSessionContextProvider: AuthenticationSessionContextProvider?
    
    /// A class that conforms to `ASWebAuthenticationPresentationContextProviding``.
    private class AuthenticationSessionContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        /// The window context that the presentation of the authentication should take place in.
        private let presentationContext: UIWindow
        
        /// Creates an instance of `AuthenticationSessionContextProvider`.
        ///
        /// - Parameters:
        ///     - presentationContext: The `UIWindow` instance to use in conforming to `ASWebAuthenticationPresentationContextProviding`.
        init(presentationContext: UIWindow) {
            self.presentationContext = presentationContext
        }
        
        @available(iOS 12.0, *)
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return presentationContext
        }
    }
}
