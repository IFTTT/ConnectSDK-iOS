//
//  Applet.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

// MARK: - Model

/// A structure that encapsulates interacting with a connect service.
public struct Applet: Equatable {
    
    /// Represents the various states an `Applet` can be in based on interaction.
    public enum Status: String {
        
        /// This Applet has never been enabled.
        case initial = "never_enabled"
        
        /// The Applet is currently enabled.
        case enabled = "enabled"
        
        /// The Applet has been disabled.
        case disabled = "disabled"
        
        /// The Applet is in an unexpected state.
        case unknown = ""
    }
    
    /// Information about a connect service.
    public struct Service: Equatable {
        
        /// The identifier of the service.
        public let id: String
        
        /// A name for the service.
        public let name: String
        
        /// Whether the service is the primary service.
        public let isPrimary: Bool
        
        /// The `URL` to a monochrome version of the icon.
        public let monochromeIconURL: URL
        
        /// The `URL` to a color version of the icon.
        public let colorIconURL: URL
        
        /// A primary color defined by the service's brand.
        public let brandColor: UIColor
        
        /// The `URL` to the service.
        public let url: URL
        
        public static func ==(lhs: Service, rhs: Service) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    /// The identifier of the `Applet`.
    public let id: String
    
    /// The name of the `Applet`.
    public let name: String
    
    /// Information about the `Applet`.
    public let description: String
    
    /// The `Status` of the `Applet`.
    public internal(set) var status: Status
    
    mutating func updating(status: Status) {
        self.status = status
    }
    
    /// The `URL` for the `Applet`.
    public let url: URL
    
    /// An array of `Service`s associated with the `Applet`.
    public let services: [Service]
    
    /// The main `Service` for the `Applet`.
    public let primaryService: Service
    
    /// An array of the `Service`s that work with this `Applet`.
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    let activationURL: URL
    
    public static func ==(lhs: Applet, rhs: Applet) -> Bool {
        return lhs.id == rhs.id
    }
}


// MARK: - Session Manager

/// A protocol that defines APIs for requesting tokens for services.
public protocol TokenProviding {
    
    /// Provides the partner OAuth token for the provided session.
    ///
    /// - Parameter session: The `Applet.Session` that the partner OAuth token is for.
    /// - Returns: A `String` that respresents the OAuth token for the partner's connection service.
    func partnerOauthTokenForServiceConnection(_ session: Applet.Session) -> String
    
    /// Provides the IFTTT user token for the provided session.
    ///
    /// - Parameter session: The `Applet.Session` that the IFTTT user token is for.
    /// - Returns: A `String` that respresents the IFTTT user token for the connection service.
    func iftttUserToken(for session: Applet.Session) -> String?
}

extension Notification.Name {
    
    /// A `Notification.Name` used to post notifications when the app recieves a redirect request for an `Applet` activation.
    static var iftttAppletActivationRedirect: Notification.Name {
        return Notification.Name("ifttt.applet.activation.redirect")
    }
}

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
        
        var userToken: String? {
            return tokenProvider.iftttUserToken(for: self)
        }
        
        var partnerToken: String {
            return tokenProvider.partnerOauthTokenForServiceConnection(self)
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


// MARK: - Requests

public extension Applet {
    
    /// Handles network requests related to the `Applet` connection service.
    public struct Request {
        
        /// The HTTP request method options.
        public enum Method: String {
            
            /// The HTTP GET method.
            case GET = "GET"
            
            /// The HTTP POST method.
            case POST = "POST"
        }
        
        /// The `Request`'s `URLRequest` that task are completed on.
        public let urlRequest: URLRequest
        
        /// A structure encapsulating responses from the `Applet` activation service network requests.
        public struct Response {
            
            /// The metadata associated with the response to network request.
            public let urlResponse: URLResponse?
            
            /// The network repsonse status code.
            public let statusCode: Int?
            
            /// The `Result` of the network request.
            public let result: Result
        }
        
        /// An enum to encapsulate success and failure responses from a network request.
        public enum Result {
            
            /// A successful result with an `Applet`.
            ///
            /// - Parameter applet: An `Applet` downloaded from the `Session`.
            case success(_ applet: Applet)
            
            /// A failure result with an optionally provided `Error`.
            ///
            /// - Parameter error: An optional `Error` with information about why the request failed.
            case failure(_ error: Error?)
        }
        
        /// A handler that is used when a `Response` is recieved from a network request.
        ///
        /// - Parameter response: The `Response` object from the completed request.
        public typealias CompletionHandler = (_ response: Response) -> Void
        
        /// A closure called when a network task has completed.
        public let completion: CompletionHandler
        
        /// Starts a network task on a `Applet`'s `Session`.
        ///
        /// - Parameter session: A `Session` to begin the network request on. Defaults to the shared session.
        public func start(with session: Session = .shared) {
            task(with: session.urlSession, urlRequest: urlRequest, minimumDuration: nil).resume()
        }
        
        /// A `Request` configured for an `Applet` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Applet`.
        ///   - completion: A `CompletionHandler` for handling the result of the request.
        /// - Returns: A `Request` configured to get the `Applet`.
        public static func applet(id: String, _ completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/applets/\(id)", method: .GET, completion: completion)
        }
        
        /// A disconnection `Request` for an `Applet` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Applet`.
        ///   - completion: A `CompletionHandler` for handling the result of the request.
        /// - Returns: A `Request` configured to disconnect the `Applet`.
        public static func disconnectApplet(id: String, _ completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/applets/\(id)/disable)", method: .POST, completion: completion)
        }
        
        func start(with session: Session = .shared, waitUntil minimumDuration: TimeInterval, timeout: TimeInterval) {
            var urlRequest = self.urlRequest
            urlRequest.timeoutInterval = timeout
            task(with: session.urlSession, urlRequest: urlRequest, minimumDuration: minimumDuration).resume()
        }
        
        private func task(with urlSession: URLSession, urlRequest: URLRequest, minimumDuration: TimeInterval?) -> URLSessionDataTask {
            let handler = { (parser: Parser, response: HTTPURLResponse?, error: Error?) in
                let statusCode = response?.statusCode
                if let applet = Applet.parseAppletsResponse(parser)?.first {
                    self.completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applet)))
                } else {
                    self.completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(error)))
                }
            }
            if let minimumDuration = minimumDuration {
                return urlSession.jsonTask(with: urlRequest, waitUntil: minimumDuration, handler)
            } else {
                return urlSession.jsonTask(with: urlRequest, handler)
            }
        }
        
        private init(path: String, method: Method, completion: @escaping CompletionHandler) {
            let url = API.base.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = Applet.Session.shared.userToken, userToken.isEmpty == false {
                request.addIftttUserToken(userToken)
            }
            if let inviteCode = Applet.Session.shared.inviteCode, inviteCode.isEmpty == false {
                request.addIftttInviteCode(inviteCode)
            }
            
            self.urlRequest = request
            self.completion = completion
        }
    }
}


// MARK: - API

struct API {
    static let base = URL(string: "https://api.ifttt.com/v2")!
}

extension URLRequest {
    mutating func addIftttUserToken(_ token: String) {
        let tokenString = "Bearer \(token)"
        addValue(tokenString, forHTTPHeaderField: "Authorization")
    }
    mutating func addIftttInviteCode(_ code: String) {
        addValue(code, forHTTPHeaderField: "IFTTT-Invite-Code")
    }
}


// MARK: - Applet connection url generation (Internal)

extension Applet {
    enum ActivationStep {
        case
        login(User.Id),
        serviceConnection(newUserEmail: String?, token: String?)
    }
    
    func activationURL(_ step: ActivationStep) -> URL {
        let session = Applet.Session.shared
        
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "sdk_return_to", value: session.appletActivationRedirect.absoluteString))
        
        if let inviteCode = session.inviteCode {
            queryItems.append(URLQueryItem(name: "invite_code", value: inviteCode))
        }
        
        switch step {
        case .login(let id):
            switch id {
            case .username(let username):
                // FIXME: Verify this param name when we have it
                queryItems.append(URLQueryItem(name: "user_id", value: username))
            case .email(let email):
                queryItems.append(URLQueryItem(name: "email", value: email))
            }
            
        case .serviceConnection(let newUserEmail, let token):
            if let email = newUserEmail {
                queryItems.append(URLQueryItem(name: "email", value: email))
                queryItems.append(URLQueryItem(name: "sdk_create_account", value: "true"))
            }
            if let token = token {
                queryItems.append(URLQueryItem(name: "token", value: token))
            }
            queryItems.append(URLQueryItem(name: "skip_sdk_redirect", value: "true"))
        }
        components?.queryItems = queryItems
        return components?.url ?? activationURL
    }
}


// MARK: - Connect configuration (Internal)

struct ConnectConfiguration {
    enum UserLookupMethod {
        case token(String), email(String)
    }
    
    let isExistingUser: Bool
    let userId: User.Id
    let partnerOpaqueToken: String?
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
            if self.partnerToken.isEmpty == false,
                let body = try? JSONSerialization.data(withJSONObject: ["token" : self.partnerToken]) {
                
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


// MARK: - URLSession (Internal)

extension URLSession {
    func jsonTask(with urlRequest: URLRequest, _ completion: @escaping (Parser, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async {
                completion(Parser(content: data), response as? HTTPURLResponse, error)
            }
        }
    }
    func jsonTask(with urlRequest: URLRequest,
                  waitUntil minimumDuration: TimeInterval,
                  _ completion: @escaping (Parser, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        var result: (Parser, HTTPURLResponse?, Error?)?
        var minimumTimeElapsed = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDuration) {
            minimumTimeElapsed = true
            if let result = result {
                completion(result.0, result.1, result.2)
            }
        }
        
        return jsonTask(with: urlRequest) { (parser, response, error) in
            if minimumTimeElapsed {
                completion(parser, response, error)
            } else {
                result = (parser, response, error)
            }
        }
    }
}
