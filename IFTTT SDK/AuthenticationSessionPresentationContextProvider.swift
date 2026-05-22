//
//  AuthenticationSessionContextProvider.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import AuthenticationServices

class AuthenticationSessionContextPresentationProvider: NSObject {
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
}

@available(iOS 12.0, *)
extension AuthenticationSessionContextPresentationProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationContext
    }
}

@available(iOS 13.0, *)
extension AuthenticationSessionContextPresentationProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationContext
    }
}
