//
//  SignInWithAppleAuthentication.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import AuthenticationServices

/// Wraps a `ASAuthorizationController`. Used for requests to Sign In With Apple.
@available(iOS 13.0, *)
final class AppleSignInWebService: ServiceAuthentication {
    
    /// Acts as the primary handler to deal with authorization completion and errors from an `ASAuthorizationController`.
    private class AuthenticationSessionAuthorizationHandler: NSObject, ASAuthorizationControllerDelegate {
        /// The completion to be called upon success or error of the flow.
        private let completion: ((Result<Completion, ErrorType>) -> Void)
        
        /// Creates an instance of `AuthenticationSessionAuthorizationHandler`.
        ///
        /// - Parameters:
        ///     - completion: A closure to execute upon success or error of the flow.
        init(completion: @escaping ((Result<Completion, ErrorType>) -> Void)) {
            self.completion = completion
            super.init()
        }
        
        @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = appleIDCredential.identityToken,
                let identitityCodeString = String(data: identityTokenData, encoding: .utf8) else {
                    completion(.failure(.invalidResponse))
                    return
            }

            completion(.success(identitityCodeString))
        }

        @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            let code = ASAuthorizationError(_nsError: error as NSError).code
            // If/else cascade rather than a switch: ASAuthorizationError.Code is
            // non-frozen and gains new cases (notInteractive in 15.4, ...) that
            // can only be referenced behind #available — a switch over them
            // either trips "switch must be exhaustive" warnings or requires
            // raising the deployment target.
            let mapped: AuthenticationError
            if code == .canceled {
                mapped = .userCanceled
            } else if code == .failed {
                mapped = .failed
            } else if code == .invalidResponse {
                mapped = .invalidResponse
            } else if code == .notHandled {
                mapped = .notHandled
            } else if #available(iOS 14.0, *), code == .presentationContextInvalid {
                mapped = .presentationContextInvalid
            } else if #available(iOS 15.4, *), code == .notInteractive {
                mapped = .notInteractive
            } else if #available(iOS 18.0, *), code == .matchedExcludedCredential {
                mapped = .matchedExcludedCredential
            } else if #available(iOS 18.2, *), code == .credentialImport {
                mapped = .credentialImport
            } else if #available(iOS 18.2, *), code == .credentialExport {
                mapped = .credentialExport
            } else {
                mapped = .unknown
            }
            completion(.failure(mapped))
        }
    }
    
    typealias Parameters = [ASAuthorization.Scope]?
    typealias Completion = String
    typealias ErrorType = AuthenticationError
        
    /// The backing `ASAuthorizationController` session.
    private var session: ASAuthorizationController?
    
    /// The authorization handler used to handle success and error responses from the system
    private var authenticationSessionAuthorizationHandler: AuthenticationSessionAuthorizationHandler?
    
    /// An instance of `AuthenticationSessionContextPresentationProvider` used to determine which context to use in showing the dialogs.
    private let authenticationSessionContextProvider: AuthenticationSessionContextPresentationProvider
    
    /// Creates an instance of `AppleSignInWebService`.
    /// - Parameters:
    ///     - authenticationSessionContextProvider: An instance of `AuthenticationSessionContextPresentationProvider` to set on the `ASAuthorizationController`.
    init(authenticationSessionContextProvider: AuthenticationSessionContextPresentationProvider) {
        self.authenticationSessionContextProvider = authenticationSessionContextProvider
    }
    
    func start(with parameters: [ASAuthorization.Scope]?, completionHandler: @escaping (Result<String, AuthenticationError>) -> Void) -> Bool {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = parameters
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        self.session = authorizationController
        self.authenticationSessionAuthorizationHandler = AuthenticationSessionAuthorizationHandler(completion: completionHandler)

        authorizationController.presentationContextProvider = authenticationSessionContextProvider
        authorizationController.delegate = authenticationSessionAuthorizationHandler
        authorizationController.performRequests()
        return true
    }
    
    func cancel() { }
}
