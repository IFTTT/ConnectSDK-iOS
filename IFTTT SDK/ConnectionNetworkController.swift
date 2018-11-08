//
//  ConnectionNetworkController.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public final class ConnectionNetworkController {
    
    private let urlSession: URLSession
    
    public convenience init() {
        self.init(urlSession: .connectionURLSession)
    }
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    
    public enum ConnectionNetworkControllerError: Error {
        case unknownResponse
    }
    
    /// A structure encapsulating responses from the `Applet` activation service network requests.
    public struct Response {
        
        /// The metadata associated with the response to network request.
        public let urlResponse: URLResponse?
        
        /// The network repsonse status code.
        public let statusCode: Int?
        
        /// The `Result` of the network request.
        public let result: Result<Applet>
    }
    
    /// A handler that is used when a `Response` is recieved from a network request.
    ///
    /// - Parameter response: The `Response` object from the completed request.
    public typealias CompletionHandler = (_ response: Response) -> Void
    
    /// Starts a network task on a `Applet`'s `Session`.
    ///
    /// - Parameter session: A `Session` to begin the network request on. Defaults to the shared session.
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
            if let applet = Applet.parseAppletsResponse(parser)?.first {
                completion(Response(urlResponse: response, statusCode: statusCode, result: .success(applet)))
            } else {
                completion(Response(urlResponse: response, statusCode: statusCode, result: .failure(error ?? ConnectionNetworkControllerError.unknownResponse)))
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
    
    func getConnectConfiguration(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        checkUser(user: user, waitUntil: waitUntil, timeout: timeout) { configuration, error in
            DispatchQueue.main.async {
                completion(configuration, error)
            }
        }
    }
    
    private func checkUser(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        switch user {
        case .email(let email):
            urlSession.jsonTask(with: makeFindUserByEmailRequest(with: email, timeout: timeout), waitUntil: waitUntil) { _, response, error in
                let configuration = ConnectConfiguration(isExistingUser: response?.statusCode == 204, userId: .email(email))
                completion(configuration, error)
                }.resume()
        case .token(let token):
            urlSession.jsonTask(with: makeFindUserByTokenRequest(with: token, timeout: timeout), waitUntil: waitUntil) { parser, _, error in
                guard let username = parser[APIConstants.userLoginKey].string else {
                    completion(nil, error)
                    return
                }
                
                let configuration = ConnectConfiguration(isExistingUser: false, userId: .username(username))
                completion(configuration, error)
                }.resume()
        }
    }
    
    private func makeFindUserByEmailRequest(with email: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserBy(email: email))
        request.timeoutInterval = timeout
        return request
    }
    
    private func makeFindUserByTokenRequest(with token: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserByToken)
        request.addIftttUserToken(token)
        request.timeoutInterval = timeout
        return request
    }
}
