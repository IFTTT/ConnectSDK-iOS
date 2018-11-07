//
//  Applet+Request.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

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
