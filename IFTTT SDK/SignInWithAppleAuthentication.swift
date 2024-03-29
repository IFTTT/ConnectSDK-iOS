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
