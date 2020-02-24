//
//  AuthenticationSession.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import SafariServices
import AuthenticationServices

/// Wrapper for ASWebAuthenticationSession, SFAuthenticationSession, and Sign in with Apple
@available(iOS 11.0, *)
final class AuthenticationSession {
    
    typealias AuthenticationSessionClosure = ((Result<AuthenticationResult, AuthenticationError>) -> Void)
    
    /// Describes the authentication methods supported by `AuthenticationSession`.
    enum AuthenticationMethod {
        
        /// Represents a standard OAuth flow.
        /// - url: The base url for the oauth flow
        /// - callbackURLScheme: An optional url scheme to use in checking for a callback
        case oauth(url: URL, callbackURLScheme: String?)
        
        /// Represents the sign in with apple flow. This technically uses OAuth underneath the hood but uses system API's to get any relevant tokens.
        /// - requestedScopes: The optional scopes of the authentication.
        @available (iOS 13.0, *)
        case signInWithApple(requestedScopes: [ASAuthorization.Scope]?)
    }
    
    enum AuthenticationResult {
        case redirectURL(URL)
        case signInWithApple(String)
    }
    
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
        authenticationSessionAuthorizationHandler = nil
    }
    
    /// Creates a `AuthenticationSession`
    ///
    /// - Parameters:
    ///   - url: The url for an OAuth page
    ///   - callbackURLScheme: The URL scheme used in the redirect or nil. If passing nil, the scheme must be defined in the app's plist.
    ///   - presentationContext: The `UIWindow` instance to use in presenting the web authentication flow.
    ///   - completionHandler: Called when authentication finishes. Returns the Result.
    @available(iOS 13.0, *)
    init(method: AuthenticationMethod, presentationContext: UIWindow, completionHandler: @escaping AuthenticationSessionClosure) {
        let sessionCompletionHandler = { (url: URL?, error: Error?) -> Void in
            guard error == nil, let url = url else {
                completionHandler(.failure(.userCanceled))
                return
            }
            completionHandler(.success(.redirectURL(url)))
        }
        
        let authenticationSessionContextProvider = AuthenticationSessionContextProvider(presentationContext: presentationContext)
        switch method {
        case .oauth(let url, let callbackURLScheme):
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: sessionCompletionHandler)
            authSession.presentationContextProvider = authenticationSessionContextProvider
            
            self.session = .webAuthSession(authSession)
            self.authenticationSessionAuthorizationHandler = nil
            
        case .signInWithApple(let requestedScopes):
            let authenticationSessionAuthorizationHandler = AuthenticationSessionAuthorizationHandler(completion: completionHandler)
            let authorizationController = AuthenticationSession.generateSignInWithAppleController(authorizationHandler: authenticationSessionAuthorizationHandler,
                                                                                                  contextProvider: authenticationSessionContextProvider,
                                                                                                  requestedScopes: requestedScopes)
            self.session = .signInWithApple(authorizationController)
            self.authenticationSessionAuthorizationHandler = authenticationSessionAuthorizationHandler
        }
        self.authenticationSessionContextProvider = authenticationSessionContextProvider
    }
    
    /// Helper method for generating an `ASAuthorizationController` used in the Sign In With Apple flow.
    ///
    /// - Parameters:
    ///     - authorizationHandler: The handler to use in setting the delegate for the `ASAuthorizationController`.
    ///     - contextProvider: The context provider to set on the `ASAuthorizationController`.
    ///     - requestedScopes: The array of requested scopes that will be requested as part of the `ASAuthorizationController`.
    @available(iOS 13.0, *)
    private static func generateSignInWithAppleController(authorizationHandler: AuthenticationSessionAuthorizationHandler, contextProvider: AuthenticationSessionContextProvider, requestedScopes: [ASAuthorization.Scope]? = nil) -> ASAuthorizationController {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = requestedScopes
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.presentationContextProvider = contextProvider
        authorizationController.delegate = authorizationHandler
        return authorizationController
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
        case .signInWithApple(let authController):
            authController.performRequests()
            return true
        }
    }
    
    /// Cancels the current authentication session and dismisses Safari
    func cancel() {
        switch session {
        case .webAuthSession(let authSession):
            authSession.cancel()
        case .safariAuthSession(let authSession):
            authSession.cancel()
        case .signInWithApple:
            return
        }
    }
    
    /// Describes the error reason for a failed `AuthenticationSession`
    ///
    /// - userCanceled: The user Cancelled the authentication session
    enum AuthenticationError: Error {
        case userCanceled
        case failed
        case invalidResponse
        case notHandled
        case unknown
    }
    
    /// We must hold a reference to the authentication session so it is not deallocated
    /// This differs from a safari view controller because it is not referenced in the parent view controllers heirarchy
    private let session: Session
    
    /// Wraps API differences between different iOS versions
    private enum Session {
        case safariAuthSession(SFAuthenticationSession)

        @available(iOS 12.0, *)
        case webAuthSession(ASWebAuthenticationSession)
        
        @available(iOS 13.0, *)
        case signInWithApple(ASAuthorizationController)
    }
    
    /// We must hold a reference to the session context provider so it's not deallocated.
    /// Only used with `ASWebAuthenticationSession` in iOS 13 and up.
    private let authenticationSessionContextProvider: AuthenticationSessionContextProvider?
    
    /// A class that conforms to `ASWebAuthenticationPresentationContextProviding``.
    private class AuthenticationSessionContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
        /// The window context that the presentation of the authentication should take place in.
        private let presentationContext: UIWindow
        
        /// Creates an instance of `AuthenticationSessionContextProvider`.
        ///
        /// - Parameters:
        ///     - presentationContext: The `UIWindow` instance to use in conforming to `ASWebAuthenticationPresentationContextProviding`.
        init(presentationContext: UIWindow) {
            self.presentationContext = presentationContext
            super.init()
        }
        
        @available(iOS 12.0, *)
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return presentationContext
        }
        
        @available(iOS 13.0, *)
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return presentationContext
        }
    }
    
    private let authenticationSessionAuthorizationHandler: AuthenticationSessionAuthorizationHandler?
    
    /// Acts as the primary handler to deal with authorization completion and errors from an `ASAuthorizationController`.
    private class AuthenticationSessionAuthorizationHandler: NSObject, ASAuthorizationControllerDelegate {
        /// The completion to be called upon success or error of the flow.
        private let completion: AuthenticationSessionClosure
        
        /// Creates an instance of `AuthenticationSessionAuthorizationHandler`.
        ///
        /// - Parameters:
        ///     - completion: A closure to execute upon success or error of the flow.
        init(completion: @escaping AuthenticationSessionClosure) {
            self.completion = completion
            super.init()
        }
        
        @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let identityTokenData = appleIDCredential.identityToken,
                    let identitityCodeString = String(data: identityTokenData, encoding: .utf8) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                completion(.success(.signInWithApple(identitityCodeString)))
            default:
                completion(.failure(.invalidResponse))
            }
        }

        @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            let authorizationError = ASAuthorizationError(_nsError: error as NSError)
            switch authorizationError.code {
            case .canceled:
                completion(.failure(.userCanceled))
            case .failed:
                completion(.failure(.failed))
            case .invalidResponse:
                completion(.failure(.invalidResponse))
            case .notHandled:
                completion(.failure(.notHandled))
            case .unknown:
                completion(.failure(.unknown))
            @unknown default:
                completion(.failure(.unknown))
            }
        }
    }
}
