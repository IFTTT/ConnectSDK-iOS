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
                NotificationCenter.default.post(name: .iftttAppletActivationRedirect, object: url)
                return true
            }
            
            return false
        }
        
        var iftttServiceToken: String? {
            return tokenProvider.iftttServiceToken
        }
        
        var partnerOAuthToken: String {
            return tokenProvider.partnerOAuthToken
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
    
    func getConnectConfiguration(user: ConnectConfiguration.UserLookupMethod,
                                 waitUntil: TimeInterval,
                                 timeout: TimeInterval,
                                 _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        
        let urlSession = Applet.Session.shared.urlSession
        var isExistingUser: Bool = false
        var userId: User.Id?
        var partnerOpaqueToken: String?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let partnerHandshake = {
            if !self.partnerOAuthToken.isEmpty, let body = try? JSONSerialization.data(withJSONObject: ["token" : self.partnerOAuthToken]) {
                
                var request = URLRequest(url: URL(string: "https://ifttt.com/access/api/handshake")!)
                request.httpMethod = "POST"
                request.httpBody = body
                request.timeoutInterval = timeout
                
                urlSession.jsonTask(with: request, waitUntil: waitUntil) { (parser, _, _error) in
                    partnerOpaqueToken = parser["token"].string
                    error = _error
                    semaphore.signal()
                }.resume()
            } else {
                semaphore.signal()
            }
        }
        let checkUser = {
            switch user {
            case .email(let email):
                userId = .email(email)
                
                let url = URL(string: "https://api.ifttt.com/v2/account/find?email=\(email)")!
                var request = URLRequest(url: url)
                request.timeoutInterval = timeout
                
                urlSession.jsonTask(with: request, waitUntil: waitUntil) { (_, response, _error) in
                    isExistingUser = response?.statusCode == 204
                    error = _error
                    semaphore.signal()
                    }.resume()
            case .token(let token):
                let url = API.base.appendingPathComponent("/me")
                var request = URLRequest(url: url)
                request.addIftttUserToken(token)
                request.timeoutInterval = timeout
                
                urlSession.jsonTask(with: request, waitUntil: waitUntil) { (parser, _, _error) in
                    if let username = parser["user_login"].string {
                        userId = .username(username)
                    }
                    error = _error
                    semaphore.signal()
                    }.resume()
            }
        }
        
        partnerHandshake()
        checkUser()
        
        DispatchQueue(label: "com.ifttt.get-connect-configuration").async {
            [partnerHandshake, checkUser].forEach { _ in semaphore.wait() }
            DispatchQueue.main.async {
                if let userId = userId {
                    completion(ConnectConfiguration(isExistingUser: isExistingUser,
                                                    userId: userId,
                                                    partnerOpaqueToken: partnerOpaqueToken), error)
                } else {
                    completion(nil, error) // Something went wrong
                }
            }
        }
    }
}