//
//  ASWebServiceAuthentication.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import AuthenticationServices

/// Wraps an `ASWebAuthenticationSession`. Used to authenticate web services on iOS 12 and up.
@available(iOS 12.0, *)
final class ASWebServiceAuthentication: WebServiceAuthentication {
    
    /// The backing `ASWebAuthenticationSession`.
    private var session: ASWebAuthenticationSession?
    
    /// We must hold a reference to the session context provider so it's not deallocated.
    /// Only used with `ASWebAuthenticationSession` in iOS 13 and up.
    private var authenticationSessionContextProvider: AuthenticationSessionContextPresentationProvider?
    
    /// Creates an instance of ASWebServiceAuthentication.
    /// - Parameters
    ///     - authenticationSessionContextProvider: An optional instance of `AuthenticationSessionContextPresentationProvider` used in configuring the web service authentication object. Optional for iOS 12 but required for iOS 13 and up.
    init(authenticationSessionContextProvider: AuthenticationSessionContextPresentationProvider?) {
        self.authenticationSessionContextProvider = authenticationSessionContextProvider
    }
    
    @discardableResult
    override func start(with parameters: Parameters, completionHandler: @escaping (Result<URL, AuthenticationError>) -> Void) -> Bool {
        let asWebAuthenticationSession = ASWebAuthenticationSession(url: parameters.url,
                                                                    callbackURLScheme: parameters.callbackURLScheme) { url, error in
            guard let url = url else {
                guard let error = error as? ASWebAuthenticationSessionError else {
                    completionHandler(.failure(.unknown))
                    return
                }
                switch error.code {
                case .canceledLogin:
                    completionHandler(.failure(.userCanceled))
                default:
                    completionHandler(.failure(.unknown))
                }
                return
            }
            completionHandler(.success(url))
        }
        
        if #available(iOS 13.0, *) {
            asWebAuthenticationSession.presentationContextProvider = authenticationSessionContextProvider
            asWebAuthenticationSession.prefersEphemeralWebBrowserSession = parameters.prefersEphemeralWebBrowserSession
        }
        self.session = asWebAuthenticationSession
        return asWebAuthenticationSession.start()
    }
    
    override func cancel() {
        session?.cancel()
    }
}
