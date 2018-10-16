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
    public let status: Status
    public let url: URL
    public let activationURL: URL
    public let services: [Service]
    
    public let primaryService: Service
    
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    public func activationURL(forUserEmail email: String?) -> URL {
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem]()
        if let email = email {
            queryItems.append(URLQueryItem(name: "email", value: email))
        }
        if let redirect = Applet.Session.shared.appletActivationRedirect {
            queryItems.append(URLQueryItem(name: "redirect_uri", value: redirect.absoluteString))
        }
        if let inviteCode = Applet.Session.shared.inviteCode {
            queryItems.append(URLQueryItem(name: "invite_code", value: inviteCode))
        }
        components?.queryItems = queryItems
        return components?.url ?? activationURL
    }
}


// MARK: - Session Manager

public protocol UserTokenProviding {
    func iftttUserToken(for session: Applet.Session) -> String?
}

public extension Applet {
    public class Session {
        public var userTokenProvider: UserTokenProviding? = nil
        
        var userToken: String? {
            return userTokenProvider?.iftttUserToken(for: self)
        }
        
        public var appletActivationRedirect: URL?
        
        public var inviteCode: String?
        
        public let urlSession: URLSession
        
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
            let task = session.urlSession.dataTask(with: urlRequest) { (data, response, error) in
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                let applet = Applet.applets(data)?.first
                DispatchQueue.main.async {
                    if let applet = applet {
                        self.completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applet)))
                    } else {
                        self.completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(error)))
                    }
                }
            }
            task.resume()
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
        
        public static func applet(id: String, _ completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/applets/\(id)", method: .GET, completion: completion)
        }
        
        public static func applet(id: String, setIsEnabled enabled: Bool, _ completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/applets/\(id)/\(enabled ? "enable" : "disable")", method: .POST, completion: completion)
        }
    }
}


// MARK: - Parsing

typealias JSON = [String : Any?]

extension Applet {
    init?(json: JSON) {
        guard
            let id = json["id"] as? String,
            let name = json["name"] as? String,
            let description = json["description"] as? String,
            let urlString = json["url"] as? String, let url = URL(string: urlString),
            let actUrlString = json["embedded_url"] as? String, let actUrl = URL(string: actUrlString) else {
                return nil
        }
        self.id = id
        self.name = name
        self.description = description
        self.status = Status(rawValue: json["user_status"] as? String ?? "") ?? .unknown
        self.services = Service.services(json["services"] as? [JSON] ?? [])
        self.url = url
        self.activationURL = actUrl
        guard let primaryService = services.first(where: { $0.isPrimary }) else {
            return nil
        }
        self.primaryService = primaryService
    }
    static func applets(_ data: Data?) -> [Applet]? {
        if let data = data, let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? JSON {
            if let type = json["type"] as? String {
                switch type {
                case "applet":
                    if let applet = Applet(json: json) {
                        return [applet]
                    }
                case "list":
                    if let appletsJson = json["data"] as? [JSON] {
                        return appletsJson.compactMap { Applet(json: $0) }
                    }
                default:
                    break
                }
            }
        }
        return nil
    }
}

extension Applet.Service {
    init?(json: JSON) {
        guard
            let id = json["service_id"] as? String,
            let name = json["service_name"] as? String,
            let monochromeIconURLString = json["monochrome_icon_url"] as? String, let monochromeIconURL = URL(string: monochromeIconURLString),
            let colorIconURLString = json["color_icon_url"] as? String, let colorIconURL = URL(string: colorIconURLString),
            let brandColorString = json["brand_color"] as? String,
            let urlString = json["url"] as? String, let url = URL(string: urlString) else {
                return nil
        }
        self.id = id
        self.name = name
        self.isPrimary = json["is_primary"] as? Bool ?? false
        self.monochromeIconURL = monochromeIconURL
        self.colorIconURL = colorIconURL
        self.brandColor = UIColor(hex: brandColorString)
        self.url = url
    }
    static func services(_ json: [JSON]) -> [Applet.Service] {
        return json.compactMap { Applet.Service(json: $0) }
    }
}
