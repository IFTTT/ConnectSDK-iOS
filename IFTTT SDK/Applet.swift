//
//  Applet.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

// MARK: - Model

public struct Applet: Equatable {
    public enum Status: String {
        case
        initial = "never_enabled",
        enabled = "enabled",
        disabled = "disabled",
        unknown = ""
    }
    
    public struct Service: Equatable {
        public let id: String
        public let name: String
        public let isPrimary: Bool
        public let monochromeIconURL: URL
        public let colorIconURL: URL
        public let brandColor: UIColor
        public let url: URL
        
        public static func ==(lhs: Service, rhs: Service) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public let id: String
    
    public let name: String
    
    public let description: String
    
    public internal(set) var status: Status
    
    public let url: URL
    
    public let services: [Service]
    
    public let primaryService: Service
    
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    let activationURL: URL
    
    public static func ==(lhs: Applet, rhs: Applet) -> Bool {
        return lhs.id == rhs.id
    }
}


// MARK: - Session Manager

public protocol TokenProviding {
    func partnerOauthTokenForServiceConnection(_ session: Applet.Session) -> String
    func iftttUserToken(for session: Applet.Session) -> String?
}

extension Notification.Name {
    static var iftttAppletActivationRedirect: Notification.Name {
        return Notification.Name("ifttt.applet.activation.redirect")
    }
}

public extension Applet {
    public class Session {
        
        public static var shared: Session {
            if let session = _shared {
                return session
            } else {
                fatalError("IFTTT SDK has not been configured. This is a programming error. It must be configured before it can be used.")
            }
        }
        
        private static var _shared: Session?
        
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
        
        public let tokenProvider: TokenProviding
        
        public let suggestedUserEmail: String
        
        public let appletActivationRedirect: URL
        
        public let inviteCode: String?
        
        public let urlSession: URLSession
        
        /// Handles redirects during applet activation
        ///
        /// - Parameters:
        ///   - url: The open url
        ///   - options: The open url options
        /// - Returns: True if this is an IFTTT SDK redirect
        public func handleApplicationRedirect(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
            // Check if the source is safari view controller and the scheme matches the SDK redirect
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
    
    public struct Request {
        
        public enum Method: String {
            case
            GET = "GET",
            POST = "POST"
        }
        
        public let urlRequest: URLRequest
        
        public struct Response {
            public let urlResponse: URLResponse?
            public let statusCode: Int?
            public let result: Result
        }
        public enum Result {
            case success(Applet), failure(Error?)
        }
        public typealias CompletionHandler = (Response) -> Void
        
        public let completion: CompletionHandler
        
        public func start(with session: Session = .shared) {
            task(with: session.urlSession, urlRequest: urlRequest, minimumDuration: nil).resume()
        }
        
        public static func applet(id: String, _ completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/applets/\(id)", method: .GET, completion: completion)
        }
        
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
