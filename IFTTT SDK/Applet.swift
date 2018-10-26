//
//  Applet.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

// MARK: - Model

public struct Applet {
    public enum Status: String {
        case
        initial = "never_enabled",
        enabled = "enabled",
        disabled = "disabled",
        unknown = ""
    }
    
    public struct Service {
        public let id: String
        public let name: String
        public let isPrimary: Bool
        public let monochromeIconURL: URL
        public let colorIconURL: URL
        public let brandColor: UIColor
        public let url: URL
    }
    
    public let id: String
    public let name: String
    public let description: String
    public private(set) var status: Status
    public let url: URL
    public let services: [Service]
    
    public let primaryService: Service
    
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    fileprivate let activationURL: URL
    
    enum ActivationStep {
        case
        login(User.ID),
        serviceConnection(newUserEmail: String?, token: String?)
    }
    
    func activationURL(_ step: ActivationStep) -> URL {
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem]()
        if let redirect = Applet.Session.shared.appletActivationRedirect {
            queryItems.append(URLQueryItem(name: "sdk_return_to", value: redirect.absoluteString))
        }
        if let inviteCode = Applet.Session.shared.inviteCode {
            queryItems.append(URLQueryItem(name: "invite_code", value: inviteCode))
        }
        
        switch step {
        case .login(let userId):
            switch userId {
            case .id(let id):
                // FIXME: Verify this param name when we have it
                queryItems.append(URLQueryItem(name: "user_id", value: id))
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
    
    mutating func updating(status: Status) {
        self.status = status
    }
}


// MARK: - Session Manager

public protocol UserTokenProviding {
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
        public var userTokenProvider: UserTokenProviding? = nil
        
        var userToken: String? {
            return userTokenProvider?.iftttUserToken(for: self)
        }
        
        var partnerToken: String {
            // FIXME: !!
            return userTokenProvider!.partnerOauthTokenForServiceConnection(self)
        }
        
        public var appletActivationRedirect: URL?
        
        public var inviteCode: String?
        
        public let urlSession: URLSession
        
        /// Handles redirects during applet activation
        ///
        /// - Parameters:
        ///   - url: The open url
        ///   - options: The open url options
        /// - Returns: True if this is an IFTTT SDK redirect
        public func handleApplicationRedirect(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
            // Check if the source is safari view controller and the scheme matches the SDK redirect
            if let source = options[.sourceApplication] as? String, url.scheme == appletActivationRedirect?.scheme && source == "com.apple.SafariViewService" {
                NotificationCenter.default.post(name: .iftttAppletActivationRedirect, object: url)
                return true
            }
            return false
        }
        
        public static let shared: Session = {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpAdditionalHeaders = [
                "Accept" : "application/json"
            ]
            let urlSession = URLSession(configuration: configuration)
            
            return Session(urlSession: urlSession)
        }()
        
        public init(urlSession: URLSession) {
            self.urlSession = urlSession
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
        
        public let api: URL
        public let path: String
        public let method: Method
        
        public var urlRequest: URLRequest
        
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
            let api = URL(string: "https://api.ifttt.com/v2")!
            
            self.api = api
            self.path = path
            self.method = method
            
            let url = api.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = Applet.Session.shared.userToken, userToken.isEmpty == false {
                let tokenString = "Bearer \(userToken)"
                request.addValue(tokenString, forHTTPHeaderField: "Authorization")
            }
            if let inviteCode = Applet.Session.shared.inviteCode, inviteCode.isEmpty == false {
                request.addValue(inviteCode, forHTTPHeaderField: "IFTTT-Invite-Code")
            }
            
            self.urlRequest = request
            self.completion = completion
        }
    }
}


// MARK: - Connect configuration

extension Applet.Session {
    
    struct ConnectConfiguration {
        let isExistingUser: Bool
        let partnerOpaqueToken: String?
    }
    
    func getConnectConfiguration(userEmail: String,
                                 waitUntil: TimeInterval,
                                 timeout: TimeInterval,
                                 _ completion: @escaping (ConnectConfiguration) -> Void) {
        
        let urlSession = Applet.Session.shared.urlSession
        var isExistingUser: Bool = false
        var partnerOpaqueToken: String?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let partnerHandshake = {
            if self.partnerToken.isEmpty == false,
                let body = try? JSONSerialization.data(withJSONObject: ["token" : self.partnerToken]) {
                
                var request = URLRequest(url: URL(string: "https://ifttt.com/access/api/handshake")!)
                request.httpMethod = "POST"
                request.httpBody = body
                request.timeoutInterval = timeout
                
                urlSession.jsonTask(with: request, waitUntil: waitUntil) { (parser, _, _) in
                    partnerOpaqueToken = parser["token"].string
                    semaphore.signal()
                }.resume()
            } else {
                semaphore.signal()
            }
        }
        let checkEmail = {
            let url = URL(string: "https://api.ifttt.com/v2/account/find?email=\(userEmail)")!
            var request = URLRequest(url: url)
            request.timeoutInterval = timeout
            
            urlSession.jsonTask(with: request, waitUntil: waitUntil) { (_, response, _) in
                isExistingUser = response?.statusCode == 204
                semaphore.signal()
            }.resume()
        }
        
        partnerHandshake()
        checkEmail()
        
        DispatchQueue(label: "com.ifttt.get-connect-configuration").async {
            [partnerHandshake, checkEmail].forEach { _ in semaphore.wait() }
            DispatchQueue.main.async {
                completion(ConnectConfiguration(isExistingUser: isExistingUser, partnerOpaqueToken: partnerOpaqueToken))
            }
        }
    }
}


// MARK: - URLSession

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


// MARK: - Parsing

typealias JSON = [String : Any?]

enum Parser {
    
    case none, dictionary(JSON), array([Parser]), value(Any)
    
    init(content: Any?) {
        if let data = content as? Data {
            let json = try? JSONSerialization.jsonObject(with: data)
            self = Parser(content: json)
        } else if let array = content as? [Any] {
            self = .array(array.map({ Parser(content: $0) }))
        } else if let dict = content as? JSON {
            self = .dictionary(dict)
        } else if let content = content {
            self = .value(content)
        } else {
            self = .none
        }
    }
    
    subscript(key: String) -> Parser {
        if case .dictionary(let json) = self, let content = json[key] {
            return Parser(content: content)
        } else {
            return .none
        }
    }
    
    /// Returns all keys at this level
    /// Returns an empty array if it is not a dictionary
    var keys: [String] {
        switch self {
        case .dictionary(let json):
            return Array(json.keys)
        default:
            return []
        }
    }
    
    var currentValue: Any? {
        if case .value(let currentValue) = self {
            return currentValue
        } else {
            return nil
        }
    }
    
    var string: String? {
        return currentValue as? String
    }
    var stringValue: String {
        return string ?? ""
    }
    
    var stringArray: [String]? {
        if case .array(let array) = self {
            return array.compactMap({ $0.string })
        } else {
            return nil
        }
    }
    var stringArrayValue: [String] {
        return stringArray ?? []
    }
    
    var bool: Bool? {
        return (currentValue as? Bool) ?? Bool(string ?? "not_a_bool")
    }
    var boolValue: Bool {
        return bool ?? false
    }
    
    var int: Int? {
        return (currentValue as? Int) ?? Int(string ?? "not_an_int")
    }
    var intValue: Int {
        return int ?? 0
    }
    
    var double: Double? {
        return (currentValue as? Double) ?? Double(string ?? "not_a_double")
    }
    var doubleValue: Double {
        return double ?? 0
    }
    
    var url: URL? {
        if let string = string {
            return URL(string: string)
        } else {
            return nil
        }
    }
    
    var color: UIColor? {
        if let string = string {
            return UIColor(hex: string)
        } else {
            return nil
        }
    }
    
    /// If self is a dictionary, append another blob with a key
    /// This is a no-op if self isn't a dictionary or parser is none
    func adding(_ parser: Parser, forKey key: String) -> Parser {
        switch self {
        case .dictionary(var json):
            switch parser {
            case .array(let array):
                json[key] = array
            case .dictionary(let dict):
                json[key] = dict
            case .value(let value):
                json[key] = value
            default:
                break
            }
            return .dictionary(json)
        default:
            return self
        }
    }
}

extension Parser: Collection {
    subscript(index: Int) -> Parser {
        if case .array(let jsonArray) = self, jsonArray.count > index {
            return jsonArray[index]
        } else {
            return .none
        }
    }
    var startIndex: Int {
        return 0
    }
    func index(after i: Int) -> Int {
        if case .array(let objects) = self {
            return objects.index(after: i)
        } else {
            return 0
        }
    }
    var endIndex: Int {
        if case .array(let objects) = self {
            return objects.count
        } else {
            return 0
        }
    }
}

extension Applet {
    init?(parser: Parser) {
        guard
            let id = parser["id"].string,
            let name = parser["name"].string,
            let description = parser["description"].string,
            let url = parser["url"].url,
            let activationUrl = parser["embedded_url"].url else {
                return nil
        }
        self.id = id
        self.name = name
        self.description = description
        self.status = Status(rawValue: parser["user_status"].string ?? "") ?? .unknown
        self.services = parser["services"].compactMap { Service(parser: $0) }
        self.url = url
        self.activationURL = activationUrl
        guard let primaryService = services.first(where: { $0.isPrimary }) else {
            return nil
        }
        self.primaryService = primaryService
    }
    static func parseAppletsResponse(_ parser: Parser) -> [Applet]? {
        if let type = parser["type"].string {
            switch type {
            case "applet":
                if let applet = Applet(parser: parser) {
                    return [applet]
                }
            case "list":
                return parser["data"].compactMap { Applet(parser: $0) }
            default:
                break
            }
        }
        return nil
    }
}

extension Applet.Service {
    init?(parser: Parser) {
        guard
            let id = parser["service_id"].string,
            let name = parser["service_name"].string,
            let monochromeIconURL = parser["monochrome_icon_url"].url,
            let colorIconURL = parser["color_icon_url"].url,
            let brandColor = parser["brand_color"].color,
            let url = parser["url"].url else {
                return nil
        }
        self.id = id
        self.name = name
        self.isPrimary = parser["is_primary"].bool ?? false
        self.monochromeIconURL = monochromeIconURL
        self.colorIconURL = colorIconURL
        self.brandColor = brandColor
        self.url = url
    }
}
