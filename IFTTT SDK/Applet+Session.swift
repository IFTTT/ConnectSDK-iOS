//
//  Applet+Session.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public extension Applet {
    
    /// Encapsulates various information used for interacting with Applet configuration and activation.
    public class Session {
        
        /// The configured shared `Session`. This must be configured with the static function `begin(tokenProvider:suggestedUserEmail:appletActivationRedirect:inviteCode:)` first before calling, otherwise it will result in an exception.
        public static var shared: Session {
            if let session = _shared {
                return session
            } else {
                fatalError("IFTTT SDK has not been configured. This is a programming error. It must be configured before it can be used.")
            }
        }
        
        private static var _shared: Session?
        
        /// Creates the shared session configured with the provided parameters. The result is discardable and can be accessed again by calling the `Session.shared` instance.
        ///
        /// - Parameters:
        ///   - tokenProvider: An object that handle providing tokens for the session.
        ///   - suggestedUserEmail: A `String` provided as the suggested user's email address for their IFTTT account. If the user already has an IFTTT account with the same email, it will use that, otherwise it will create them a new account with this email.
        ///   - appletActivationRedirect: A `URL` used as the activation redirection endpoint. This must be registered on `platform.ifttt.com` and set in the applications `Info.plist`.
        ///   - inviteCode: An optional `String` containing an invitation code for the session. Used when testing unpublished services. The code can be found on `platform.ifttt.com`.
        /// - Returns: A configured `Session`, to use on the `Applet`. This is discardable and can be accessed again by calling the `Session.shared` instance.
        @discardableResult
        static public func begin(tokenProvider: TokenProviding, suggestedUserEmail: String, appletActivationRedirect: URL, inviteCode: String?) -> Session {
            assert(suggestedUserEmail.isValidEmail, "You must provide a valid email address for the user")
            
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpAdditionalHeaders = [
                "Accept" : "application/json"
            ]
            let urlSession = URLSession(configuration: configuration)
            
            _shared = Session(urlSession: urlSession,
                              tokenProvider: tokenProvider,
                              suggestedUserEmail: suggestedUserEmail,
                              appletActivationRedirect: appletActivationRedirect,
                              inviteCode: inviteCode)
            return shared
        }
        
        /// An object that handle providing tokens for the session.
        public let tokenProvider: TokenProviding
        
        /// A `String` provided as the suggested user's email address.
        public let suggestedUserEmail: String
        
        /// A `URL` used as the activation redirection endpoint.
        public let appletActivationRedirect: URL
        
        /// An optional `String` containing an invitation code for the session.
        public let inviteCode: String?
        
        /// An object for handling network data transfer tasks for the session.
        public let urlSession: URLSession
        
        /// Handles redirects during applet activation.
        ///
        /// Generally, this is used to handle url redirects the app recieves in `func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool` in the `AppDelgate`.
        /// - Example: `Applet.Session.shared.handleApplicationRedirect(url: url, options: options)`.
        ///
        /// - Parameters:
        ///   - url: The `URL` resource to open.
        ///   - options: A dictionary of `URL` handling options. For information about the possible keys in this dictionary, see UIApplicationOpenURLOptionsKey.
        /// - Returns: True if this is an IFTTT SDK redirect. False for any other `URL`.
        public func handleApplicationRedirect(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
            
            // Checks if the source is `SafariViewService` and the scheme matches the SDK redirect.
            if let source = options[.sourceApplication] as? String, url.scheme == appletActivationRedirect.scheme && source == "com.apple.SafariViewService" {
                NotificationCenter.default.post(name: .appletActivationRedirect, object: url)
                return true
            }
            
            return false
        }
        
        var iftttServiceToken: String? {
            return tokenProvider.iftttServiceToken
        }
        
        var partnerOAuthCode: String {
            return tokenProvider.partnerOAuthCode
        }
        
        private init(urlSession: URLSession,
                     tokenProvider: TokenProviding,
                     suggestedUserEmail: String,
                     appletActivationRedirect: URL,
                     inviteCode: String?) {
            self.urlSession = urlSession
            self.tokenProvider = tokenProvider
            self.suggestedUserEmail = suggestedUserEmail
            self.appletActivationRedirect = appletActivationRedirect
            self.inviteCode = inviteCode
        }
    }
}

extension Applet.Session {
    
    private enum APIConstants {
        static let userLoginKey = "user_login"
    }
    
    func getConnectConfiguration(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        checkUser(user: user, waitUntil: waitUntil, timeout: timeout) { configuration, error in
            DispatchQueue.main.async {
                completion(configuration, error)
            }
        }
    }
    
    private func checkUser(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        switch user {
        case .email(let email):
            urlSession.jsonTask(with: makeFindUserByEmailRequest(with: email, timeout: timeout), waitUntil: waitUntil) { _, response, error in
                let configuration = ConnectConfiguration(isExistingUser: response?.statusCode == 204, userId: .email(email))
                completion(configuration, error)
            }.resume()
        case .token(let token):
            urlSession.jsonTask(with: makeFindUserByTokenRequest(with: token, timeout: timeout), waitUntil: waitUntil) { parser, _, error in
                guard let username = parser[APIConstants.userLoginKey].string else {
                    completion(nil, error)
                    return
                }
                
                let configuration = ConnectConfiguration(isExistingUser: false, userId: .username(username))
                completion(configuration, error)
            }.resume()
        }
    }
    
    private func makeFindUserByEmailRequest(with email: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserBy(email: email))
        request.timeoutInterval = timeout
        return request
    }
    
    private func makeFindUserByTokenRequest(with token: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserByToken)
        request.addIftttUserToken(token)
        request.timeoutInterval = timeout
        return request
    }
}

