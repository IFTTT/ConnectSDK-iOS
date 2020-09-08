//
//  ConnectionVerificationSession.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation
import SafariServices
import AuthenticationServices

/// Handles verification of the connection in the web flow. For iOS 10, the flow defaults to ocurring in a `SFSafariViewController. For iOS 11, the flow occurs in a `ASWebAuthenticationSession`. For iOS 12 and up, the flow occurs in a `SFAuthenticationSession`.
/// We use these sessions instead of showing in `SFSafariViewController` as we can leverage cookies from previous connection verifications or a currently logged in IFTTT account and not have to worry about going through the verification flow multiple times.
final class ConnectionVerificationSession {
    
    /// Creates a `ConnectionVerificationSession`. Starts observation of redirects if it is required.
    init() {
        self.setupObserving()
    }
    
    /// Dismisses a authentication session in progress. Call this once after the redirect is complete.
    ///
    /// - Parameters:
    ///     - isUserCancelled: True if the dismissal was user initiated.
    ///     - completion: A closure that gets called after the dismissal is complete.
    func dismiss(isUserCancelled: Bool, completion: @escaping VoidClosure) {
        guard let authProvider = authProvider else {
            // If we don't have an auth provider, call the completion handler right away.
            completion()
            return
        }
        switch authProvider {
        case .authSession(let authSession):
            if !isUserCancelled {
                authSession.cancel()
            }
            completion()
        case .safari(let safariViewController):
            safariViewController.dismiss(animated: true, completion: completion)
        }
    }

    /// Begins the connection verification session
    /// This will prompt the user's permission if necessary.
    ///
    /// - Parameters:
    ///     - url: The url to kick off the connection verification with.
    ///     - presentationContext: The `UIWindow` instance to use in presenting the web auth flow. The system may present an alert.
    @available(iOS 13.0, *)
    func start(with url: URL, in presentationContext: UIWindow) {
        let authenticationMethod = AuthenticationSession.AuthenticationMethod.oauth(url: url, callbackURLScheme: nil, prefersEphemeralWebBrowserSession: false)
        let authenticationSession = AuthenticationSession(method: authenticationMethod, presentationContext: presentationContext) { [weak self] (result) in
            switch result {
            case .success(let result):
                self?.handleAuthenticationResult(result)
            case .failure(let error):
                switch error {
                case .userCanceled:
                    self?.redirectHandler.handleUserCancelled()
                default:
                    self?.redirectHandler.handleUnknown()
                }
            }
        }
        authenticationSession.start()
        authProvider = .authSession(authenticationSession)
    }
    
    /// Begins the connection verification session
    /// This will prompt the user's permission if necessary.
    ///
    /// - Parameters:
    ///     - viewController: The view controller initiating this session. We may present an alert or a Safari VC.
    ///     - url: The url to kick off the connection verification with.
    @available(iOS, obsoleted: 13, message: "API is obsoleted in iOS 13. Please use `start(with url: URL, in presentationContext: UIWindow)` instead.")
    func start(from viewController: UIViewController, with url: URL) {
        if #available(iOS 11, *) {
            let authenticationSession = AuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] (result) in
                switch result {
                case .success(let url):
                    self?.redirectHandler.handleRedirect(url: url)
                case .failure(let error):
                    self?.handleAuthenticationError(error)
                }
            }
            authenticationSession.start()
            authProvider = .authSession(authenticationSession)
        } else {
            let safari = SFSafariViewController(url: url)
            safari.delegate = cancellationObserver
            if #available(iOS 11.0, *) {
                safari.dismissButtonStyle = .cancel
            }
            authProvider = .safari(safari)
            viewController.present(safari, animated: true, completion: nil)
        }
    }
    
    /// Handles authentication success.
    ///
    /// - Parameters:
    ///     - result: An instance of `AuthenticationSession.AuthenticationResult` that gets returned from a successful authentication.
    @available(iOS 11.0, *)
    private func handleAuthenticationResult(_ result: AuthenticationSession.AuthenticationResult) {
        switch result {
        case .redirectURL(let url):
            redirectHandler.handleRedirect(url: url)
        default:
            redirectHandler.handleUnknown()
        }
    }
    
    /// Handles authentication error.
    ///
    /// - Parameters:
    ///     - result: An instance of `AuthenticationSession.AuthenticationError` that gets returned from an authentication error.
    @available(iOS 11.0, *)
    private func handleAuthenticationError(_ error: AuthenticationSession.AuthenticationError) {
        switch error {
        case .userCanceled:
            redirectHandler.handleUserCancelled()
        default:
            redirectHandler.handleUnknown()
        }
    }
    
    // MARK: - State tracking
    
    /// We have to use a different method on iOS 10 and 11 for an authentication session due to iOS changes
    private enum AuthenticationProvider {
        @available(iOS 11.0, *)
        case authSession(AuthenticationSession)
        
        case safari(SFSafariViewController)
        
        func cancel() {
            switch self {
            case .authSession(let session):
                session.cancel()
            case .safari(let vc):
                vc.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    /// Hold on to the instance of the authentication session so it is not deallocated
    private var authProvider: AuthenticationProvider?
    
    /// Corresponds to an outcome from the session
    enum Outcome {
        /// The connection was successfully connected.
        /// The associated value corresponds to the user token that gets returned from the activation. This may be nil.
        case token(String?)
        /// There was an error during activation.
        /// The associated value corresponds to the exact error that occurred.
        case error(ConnectButtonControllerError)
        /// The user needs to enter an email.
        case email
    }
    
    typealias CompletionHandler = (Outcome) -> Void
    
    /// Completion closure called once the authentication session has finished
    var completionHandler: CompletionHandler? {
        didSet {
            redirectHandler.completionHandler = completionHandler
        }
    }
    
    /// An object to handle any redirects from either
    private let redirectHandler = RedirectHandler()
    
    /// An object to handle the case in which the user cancels during the web flow
    private var cancellationObserver: CancellationObserver?
    
    deinit {
        authProvider?.cancel()
        authProvider = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Handle response

private extension ConnectionVerificationSession {
    
    /// Handles redirects from the webflow.
    private final class RedirectHandler {
        
        private struct QueryItems {
            static let nextStep = "next_step"
            static let userCancelledConfiguration = "user_cancelled_configuration"
            static let complete = "complete"
            static let userToken = "user_token"
            static let error = "error"
            static let errorType = "error_type"
            static let errorTypeAccountCreation = "account_creation"
        }
        
        /// A completion handler that gets called as a result of processing redirects
        var completionHandler: CompletionHandler?
        
        /// Handles a redirect from a `Notification`.
        ///
        /// - Parameters:
        ///     - notification: The `Notification` that gets returned as a result of registering for notifications.
        func handleRedirect(_ notification: Notification) {
            handleRedirect(url: notification.object as? URL)
        }
        
        /// Handles a redirect from a `URL?`. This url contains information on whether or not the connection activation was successful.
        ///
        /// - Parameters:
        ///     - url: The url that prompted returning back to the app and sdk.
        func handleRedirect(url: URL?) {
            guard
                let url = url,
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let queryItems = components.queryItems,
                let nextStep = queryItems.first(where: { $0.name == QueryItems.nextStep })?.value
                else {
                    completionHandler?(.error(.unknownRedirect))
                    return
            }
            
            switch nextStep {
            case QueryItems.complete:
                let userToken = queryItems.first(where: { $0.name == QueryItems.userToken })?.value
                completionHandler?(.token(userToken))
                
            case QueryItems.error:
                if let reason = queryItems.first(where: { $0.name == QueryItems.errorType })?.value, reason == QueryItems.errorTypeAccountCreation {
                    completionHandler?(.error(.iftttAccountCreationFailed))
                } else {
                    completionHandler?(.error(.unknownRedirect))
                }
                
            case QueryItems.userCancelledConfiguration:
                completionHandler?(.error(.userCancelledConfiguration))
                
            default:
                completionHandler?(.error(.unknownRedirect))
            }
        }
        
        /// Handles a user cancellation during the web flow.
        func handleUserCancelled() {
            completionHandler?(.error(.canceled))
        }
        
        /// Handles unknown responses and failed responses
        func handleUnknown() {
            completionHandler?(.error(.unknownResponse))
        }
        
        /// Handles a user cancellation with a lookup method that was used to find the user.
        ///
        /// - Parameters:
        ///     - lookupMethod: The method in which the user was looked up.
        func handleCancellation(lookupMethod: User.LookupMethod) {
            switch lookupMethod {
            case .email:
                completionHandler?(.email)
            case .token:
                completionHandler?(.error(.canceled))
            }
        }
    }
}

// MARK: - Handle cancelation and redirection for iOS 10 devices
private extension ConnectionVerificationSession {
    /// Acts as a SFSafariViewControllerDelegate to monitor authorization cancelation
    class CancellationObserver: NSObject, SFSafariViewControllerDelegate {
        private let callback: () -> Void
        
        init(cancelationCallback: @escaping () -> Void) {
            callback = cancelationCallback
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            callback()
        }
    }
}


extension ConnectionVerificationSession {
    /// Starts the observing for redirects back to the app from outside the app completely.
    private func setupObserving() {
        NotificationCenter.default.addObserver(forName: .connectionRedirect, object: nil, queue: .main) { [weak self] notification in
            self?.redirectHandler.handleRedirect(notification)
        }
    }
    
    /// Starts the observing for redirects back to the app from  `SFSafariViewController`.
    func beginObservingSafariRedirects(with lookupMethod: User.LookupMethod) {
        cancellationObserver = CancellationObserver(cancelationCallback: { [weak self] in
            self?.redirectHandler.handleCancellation(lookupMethod: lookupMethod)
        })
    }
    
    /// Once activation is finished or Cancelled, tear down redirect and cancelation observing
    func endActivationWebFlow() {
        cancellationObserver = nil
        authProvider = nil
    }
}
