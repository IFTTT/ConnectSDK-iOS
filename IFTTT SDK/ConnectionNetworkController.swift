//
//  ConnectionNetworkController.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// A controller for handling making network request for `Connection`s.
public final class ConnectionNetworkController: JSONNetworkController {
    
    /// Creates a `ConnectionNetworkController`.
    public convenience init() {
        self.init(urlSession: .connectionURLSession)
    }
    
    /// A structure encapsulating responses from the `Connection` activation service network requests.
    public struct Response: ResponseDescription {
        
        init(jsonResponse: JSONNetworkController.Response) {
            if let applet = Connection.parseAppletsResponse(jsonResponse.data)?.first {
                self.result = .success(applet)
            } else {
                self.result = .failure(.unknownResponse)
            }
            self.statusCode = jsonResponse.statusCode
        }
        
        init(error: Error) {
            self.statusCode = -1
            self.result = .failure(.genericError(error))
        }
        
        /// The network repsonse status code.
        public let statusCode: Int
        
        /// The `Result<Connection>` of the network request.
        public var result: Result<Connection, ConnectionNetworkError>
    }
    
    /// A handler that is used when a `Response` is recieved from a network request.
    ///
    /// - Parameter response: The `Response` object from the completed request.
    public typealias ConnectionResponseClosure = (_ response: Response) -> Void
    

    /// Starts a task to fetch information about a `Connection`.
    ///
    /// - Parameters:
    ///   - request: A `Connection.Request` to complete the network request on.
    ///   - completion: A `ConnectionResponseClosure` for providing a response of the data recieved from the request or an error that occured.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    public func start(request: Connection.Request, completion: @escaping ConnectionResponseClosure) -> URLSessionDataTask {
        return start(urlRequest: request.urlRequest, completion: completion)
    }
    
    /// Starts a task to fetch information from the network for the provided request.
    ///
    /// - Parameters:
    ///   - urlRequest: A `URLRequest` to complete the network request on.
    ///   - completion: A `ConnectionResponseClosure` for providing a response of the data recieved from the request or an error that occured.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    public func start(urlRequest: URLRequest, completion: @escaping ConnectionResponseClosure) -> URLSessionDataTask {
        let dataTask = task(urlRequest: urlRequest, completion: completion)
        dataTask.resume()
        return dataTask
    }
    
    private func task(urlRequest: URLRequest, completion: @escaping ConnectionResponseClosure) -> URLSessionDataTask {
        return json(urlRequest: urlRequest) { (result) in
            switch result {
            case .success(let jsonResponse):
                completion(.init(jsonResponse: jsonResponse))
            case .failure(let error):
                completion(.init(error: error))
            }
        }
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
    func fetchUser(lookupMethod: User.LookupMethod, _ completion: @escaping (Result<User, NetworkControllerError>) -> Void) -> URLSessionDataTask? {
        return checkUser(user: lookupMethod) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func checkUser(user: User.LookupMethod, _ completion: @escaping (Result<User, NetworkControllerError>) -> Void) -> URLSessionDataTask? {
        switch user {
        case .email(let email):
            guard let request = makeFindUserByEmailRequest(with: email) else {
                return nil
            }
            
            return json(urlRequest: request) { (result) in
                switch result {
                case .success(let response):
                    let user = User(id: .email(email), isExistingUser: response.statusCode == 204)
                    completion(.success(user))
                case .failure:
                    let user = User(id: .email(email), isExistingUser: false)
                    completion(.success(user))
                }
            }
        case .token(let token):
            return json(urlRequest: makeFindUserByTokenRequest(with: token)) { (result) in
                switch result {
                case .success(let response):
                    guard let username = response.data[APIConstants.userLoginKey].string else {
                        completion(.failure(.unknownResponse))
                        return
                    }
                    
                    let user = User(id: .username(username), isExistingUser: true)
                    completion(.success(user))
                    
                case .failure(let error):
                    completion(.failure(.genericError(error)))
                }
            }
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
