//
//  ConnectionNetworkController.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A controller for handling making network request for `Connection`s.
public final class ConnectionNetworkController {
    
    private let urlSession: URLSession
    
    /// Creates a `ConnectionNetworkController`.
    public convenience init() {
        self.init(urlSession: .connectionURLSession)
    }
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    /// A structure encapsulating responses from the `Connection` activation service network requests.
    public struct Response {
        
        /// The metadata associated with the response to network request.
        public let urlResponse: URLResponse?
        
        /// The network repsonse status code.
        public let statusCode: Int?
        
        /// The `Result<Connection>` of the network request.
        public let result: Result<Connection, NetworkError>
    }
    
    /// A handler that is used when a `Response` is recieved from a network request.
    ///
    /// - Parameter response: The `Response` object from the completed request.
    public typealias CompletionHandler = (_ response: Response) -> Void

    /// Starts a task to fetch information about a `Connection`.
    ///
    /// - Parameters:
    ///   - request: A `Connection.Request` to complete the network request on.
    ///   - completion: A `CompletionHandler` for providing a response of the data recieved from the request or an error that occured.
    public func start(request: Connection.Request, completion: @escaping CompletionHandler) {
        start(urlRequest: request.urlRequest, completion: completion)
    }
    
    /// Starts a task to fetch information from the network for the provided request.
    ///
    /// - Parameters:
    ///   - urlRequest: A `URLRequest` to complete the network request on.
    ///   - completion: A `CompletionHandler` for providing a response of the data recieved from the request or an error that occured.
    public func start(urlRequest: URLRequest, completion: @escaping CompletionHandler) {
        task(urlRequest: urlRequest, minimumDuration: nil, completion: completion).resume()
    }
    
    func start(urlRequest: URLRequest, waitUntil minimumDuration: TimeInterval, timeout: TimeInterval, completion: @escaping CompletionHandler) {
        var urlRequest = urlRequest
        urlRequest.timeoutInterval = timeout
        task(urlRequest: urlRequest, minimumDuration: minimumDuration, completion: completion).resume()
    }
    
    private func task(urlRequest: URLRequest, minimumDuration: TimeInterval?, completion: @escaping CompletionHandler) -> URLSessionDataTask {
        let handler = { (parser: Parser, response: HTTPURLResponse?, error: Error?) in
            let statusCode = response?.statusCode
            if let applet = Connection.parseAppletsResponse(parser)?.first {
                completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applet)))
            } else {
                let networkError: NetworkError = {
                    if let error = error {
                        return .genericError(error)
                    } else {
                        return .unknownResponse
                    }
                }()
                completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(networkError)))
            }
        }
        if let minimumDuration = minimumDuration {
            return urlSession.jsonTask(with: urlRequest, waitUntil: minimumDuration, handler)
        } else {
            return urlSession.jsonTask(with: urlRequest, handler)
        }
    }
    
    private enum APIConstants {
        static let userLoginKey = "user_login"
    }
    
    func getConnectConfiguration(user: User.LookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (Result<User, NetworkError>) -> Void) -> URLSessionDataTask {
        return checkUser(user: user, waitUntil: waitUntil, timeout: timeout) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func checkUser(user: User.LookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (Result<User, NetworkError>) -> Void) -> URLSessionDataTask {
        switch user {
        case .email(let email):
            let dataTask = urlSession.jsonTask(with: makeFindUserByEmailRequest(with: email, timeout: timeout), waitUntil: waitUntil) { _, response, error in
                let configuration = User(id: .email(email), isExistingUser: response?.statusCode == 204)
                completion(.success(configuration))
                
            }
            dataTask.resume()
        
            return dataTask
        case .token(let token):
            let dataTask = urlSession.jsonTask(with: makeFindUserByTokenRequest(with: token, timeout: timeout), waitUntil: waitUntil) { parser, _, error in
                guard let username = parser[APIConstants.userLoginKey].string else {
                    if let networkError = error {
                        completion(.failure(.genericError(networkError)))
                    } else {
                        completion(.failure(.unknownResponse))
                    }
                    return
                }
                
                let configuration = User(id: .username(username), isExistingUser: false)
                completion(.success(configuration))
            }
            dataTask.resume()
            
            return dataTask
        }
    }
    
    private func makeFindUserByEmailRequest(with email: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserBy(email: email))
        request.timeoutInterval = timeout
        request.addVersionTracking()
        return request
    }
    
    private func makeFindUserByTokenRequest(with token: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserByToken)
        request.addIftttServiceToken(token)
        request.timeoutInterval = timeout
        request.addVersionTracking()
        return request
    }
}
