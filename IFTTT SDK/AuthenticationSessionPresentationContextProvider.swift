//
//  AuthenticationSessionContextProvider.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import AuthenticationServices

/// A class that conforms to `ASWebAuthenticationPresentationContextProviding`.
class AuthenticationSessionContextPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
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
