//
//  ConnectionNetworkController.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// A controller for handling making network request for `Connection`s.
public final class ConnectionNetworkController {
    
    private let urlSession: URLSession
    
    /// Creates a `ConnectionNetworkController`.
    public convenience init() {
        self.init(urlSession: .connectionURLSession)
    }
    
    /// Creates a `ConnectionNetworkController`.
    ///
    /// - Parameter urlSession: A `URLSession` to make request on.
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
        public let result: Result<Connection, ConnectionNetworkError>
    }
    
    /// A handler that is used when a `Response` is recieved from a network request.
    ///
    /// - Parameter response: The `Response` object from the completed request.
    public typealias CompletionHandler = (_ response: Response) -> Void
    
    /// Cancels any in-flight requests that were sent from this network controller
    public func cancel() {
        urlSession.invalidateAndCancel()
    }

    /// Starts a task to fetch information about a `Connection`.
    ///
    /// - Parameters:
    ///   - request: A `Connection.Request` to complete the network request on.
    ///   - completion: A `CompletionHandler` for providing a response of the data recieved from the request or an error that occured.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    public func start(request: Connection.Request, completion: @escaping CompletionHandler) -> URLSessionDataTask {
        return start(urlRequest: request.urlRequest, completion: completion)
    }
    
    /// Starts a task to fetch information from the network for the provided request.
    ///
    /// - Parameters:
    ///   - urlRequest: A `URLRequest` to complete the network request on.
    ///   - completion: A `CompletionHandler` for providing a response of the data recieved from the request or an error that occured.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    public func start(urlRequest: URLRequest, completion: @escaping CompletionHandler) -> URLSessionDataTask {
        let dataTask = task(urlRequest: urlRequest, completion: completion)
        dataTask.resume()
        return dataTask
    }
    
    private func task(urlRequest: URLRequest, completion: @escaping CompletionHandler) -> URLSessionDataTask {
        let handler = { (parser: Parser, response: HTTPURLResponse?, error: Error?) in
            let statusCode = response?.statusCode
            if let applet = Connection.parseAppletsResponse(parser)?.first {
                completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applet)))
            } else {
                let networkError: ConnectionNetworkError = {
                    if let error = error {
                        return .genericError(error)
                    } else {
                        return .unknownResponse
                    }
                }()
                completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(networkError)))
            }
        }
        return urlSession.jsonTask(with: urlRequest, handler)
    }
    
    private enum APIConstants {
        static let userLoginKey = "user_login"
    }
    
    /// Fetches a `User` based on the provided lookup method.
    ///
    /// - Parameters:
    ///   - lookupMethod: Tells the controller how to identify the user’s IFTTT account.
    ///   - completion: A results of either the user or an error from looking up their IFTTT acount.
    /// - Returns: An optional `URLSessionDataTask` of the user fetching request.
    func fetchUser(lookupMethod: User.LookupMethod, _ completion: @escaping (Result<User, ConnectionNetworkError>) -> Void) -> URLSessionDataTask? {
        return checkUser(user: lookupMethod) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func checkUser(user: User.LookupMethod, _ completion: @escaping (Result<User, ConnectionNetworkError>) -> Void) -> URLSessionDataTask? {
        switch user {
        case .email(let email):
            guard let request = makeFindUserByEmailRequest(with: email) else {
                return nil
            }
            
            let dataTask = urlSession.jsonTask(with: request) { _, response, error in
                let user = User(id: .email(email), isExistingUser: response?.statusCode == 204)
                completion(.success(user))
                
            }
            dataTask.resume()
        
            return dataTask
        case .token(let token):
            let dataTask = urlSession.jsonTask(with: makeFindUserByTokenRequest(with: token)) { parser, _, error in
                guard let username = parser[APIConstants.userLoginKey].string else {
                    if let networkError = error {
                        completion(.failure(.genericError(networkError)))
                    } else {
                        completion(.failure(.unknownResponse))
                    }
                    return
                }
                
                let user = User(id: .username(username), isExistingUser: true)
                completion(.success(user))
            }
            dataTask.resume()
            
            return dataTask
        }
    }
    
    private func makeFindUserByEmailRequest(with email: String) -> URLRequest? {
        guard let url = API.findUserBy(email: email) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.addVersionTracking()
        return request
    }
    
    private func makeFindUserByTokenRequest(with token: String) -> URLRequest {
        var request = URLRequest(url: API.findUserByToken)
        request.addIftttServiceToken(token)
        request.addVersionTracking()
        return request
    }
}
