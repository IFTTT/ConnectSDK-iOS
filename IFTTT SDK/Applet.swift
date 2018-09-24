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
    public let services: [Service]
    
    public var primaryService: Service! {
        return services.first(where: { $0.isPrimary })
    }
    
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
}


// MARK: - Session Manager

public extension Applet {
    public class Session {
        public var serviceId: String = "ifttt"
        
        public var userToken: String? = nil
        
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
        public enum Parameter {
            public enum Sort: String {
                case
                unknown = "" // FIXME: !!
            }
            public enum Filter: String {
                case
                pinned = "pinned_only",
                enabled = "user_enabled_only"
            }
            
            case
            limit(Int),
            nextPage(String),
            sort(Sort),
            filter(Filter)
            
            var formatted: (name: String, value: String) {
                switch self {
                case .limit(let limit):
                    return ("limit", "\(limit)")
                case .nextPage(let cursor):
                    return ("next_page", cursor)
                case .sort(let sort):
                    return ("sort", sort.rawValue)
                case .filter(let filter):
                    return ("filter", filter.rawValue)
                }
            }
        }
        
        public let api: URL
        public let path: String
        public let method: Method
        public let paramters: [Parameter]
        
        public let urlRequest: URLRequest
        
        public struct Response {
            public let urlResponse: URLResponse?
            public let statusCode: Int?
            public let result: Result
        }
        public enum Result {
            case success([Applet]), failure(Error?)
        }
        public typealias CompletionHandler = (Response) -> Void
        
        public let completion: CompletionHandler
        
        public func start(with session: Session = .shared) {
            let task = session.urlSession.dataTask(with: urlRequest) { (data, response, error) in
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                let applets = Applet.applets(data)
                DispatchQueue.main.async {
                    if let applets = applets {
                        self.completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applets)))
                    } else {
                        self.completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(error)))
                    }
                }
            }
            task.resume()
        }
        
        private init(path: String, method: Method, paramters: [Parameter] = [], completion: @escaping CompletionHandler) {
            let api = URL(string: "https://api.ifttt.com/v1")!
            
            self.api = api
            self.path = path
            self.method = method
            self.paramters = paramters
            
            let url: URL = {
                var url = api.appendingPathComponent(path)
                if method == .GET, var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    urlComponents.queryItems = URLEncoding.with(paramaters: paramters)
                    url = urlComponents.url ?? url
                }
                return url
            }()
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if method == .POST {
                request.httpBody = DataEncoding.with(paramaters: paramters)
            }
            
            if let userToken = Applet.Session.shared.userToken, userToken.isEmpty == false {
                let tokenString = "Bearer \(userToken)"
                request.addValue(tokenString, forHTTPHeaderField: "Authorization")
            }
            
            self.urlRequest = request
            self.completion = completion
        }
        
        public static func applets(forService id: String = Applet.Session.shared.serviceId,
                                   parameters: [Parameter] = [],
                                   completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/services/\(id)/applets", method: .GET, paramters: parameters, completion: completion)
        }
        
        public static func applet(id: String,
                                  forService serviceId: String = Applet.Session.shared.serviceId,
                                  completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/services/\(serviceId)/applets/\(id)", method: .GET, completion: completion)
        }
        
        public static func applet(id: String,
                                  forService serviceId: String = Applet.Session.shared.serviceId,
                                  setIsEnabled enabled: Bool,
                                  completion: @escaping CompletionHandler) -> Request {
            return Request(path: "/services/\(serviceId)/applets/\(id)/\(enabled ? "enable" : "disable")", method: .POST, completion: completion)
        }
    }
}


// MARK: - Parameter encoding

private protocol Encoding {
    associatedtype Output
    
    static func with(paramaters: [Applet.Request.Parameter]) -> Output
}

private struct DataEncoding: Encoding {
    static func with(paramaters: [Applet.Request.Parameter]) -> Data? {
        var json = [String : String]()
        paramaters.forEach {
            json[$0.formatted.name] = $0.formatted.value
        }
        return try? JSONSerialization.data(withJSONObject: json)
    }
}

private struct URLEncoding: Encoding {
    static func with(paramaters: [Applet.Request.Parameter]) -> [URLQueryItem] {
        return paramaters.map {
            return URLQueryItem(name: $0.formatted.name, value: $0.formatted.value)
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
            let description = json["description"] as? String else {
                return nil
        }
        self.id = id
        self.name = name
        self.description = description
        self.status = Status(rawValue: json["user_status"] as? String ?? "") ?? .unknown
        self.services = Service.services(json["services"] as? [JSON] ?? [])
        
        guard primaryService != nil else {
            return nil
        }
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
