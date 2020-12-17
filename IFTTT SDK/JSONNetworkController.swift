//
//  JSONNetworkController.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Describes informations about a network response
protocol ResponseDescription {
    
    /// The status code for the response
    var statusCode: Int { get }
    
    /// Determines whether or not the response is valid.
    ///
    /// By default only status codes in the 200..<300 range are determined to be valid.
    var isValidResponse: Bool { get }
    
    /// Determines whether the response resulted in an authentication failure
    ///
    /// By default, a status code of 401 is determined to be an authentication failure.
    var isAuthenticationFailure: Bool { get }
}

extension ResponseDescription {
    
    var isValidResponse: Bool {
        return (200..<300).contains(statusCode)
    }
    
    var isAuthenticationFailure: Bool {
        return statusCode == 401
    }
}

/// A network controller used in making requsts with JSON responses.
public class JSONNetworkController {
    
    /// A closure that describes the result of the network response
    public typealias CompletionClosure = (Result<Response, Error>) -> Void
    
    /// Encapsulates all of the information corresponding to a valid network response.
    public struct Response: ResponseDescription {
        
        /// The status code for the response
        let statusCode: Int
        
        /// The data that gets generated as a result of parsing the response
        let data: Parser
        
        /// The dictionary of HTTP headers fields that got returned on the response.
        let allHTTPHeaderFields: [AnyHashable: Any]
        
        /// Creates an instance of `Response`.
        ///
        /// - Parameters:
        ///     - httpURLResponse: A `HTTPURLResponse` that gets returned from the system HTTP response methods.
        ///     - data: A `Parser` that's generated from parsing the result response data.
        init(httpURLResponse: HTTPURLResponse, data: Parser) {
            self.statusCode = httpURLResponse.statusCode
            self.data = data
            self.allHTTPHeaderFields = httpURLResponse.allHeaderFields
        }
    }
    
    /// The backing `URLSession` to make network requests with.
    private let urlSession: URLSession
    
    /// Creates a `NetworkController`.
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    /// Cancels any in-flight requests that were sent from this network controller
    func cancel() {
        urlSession.invalidateAndCancel()
    }

    /// Starts a task to fetch JSON from the network for the provided request.
    ///
    /// - Parameters:
    ///   - urlRequest: A `URLRequest` to complete the network request on.
    ///   - completionHandler: An optional instance of `CompletionClosure` for providing a response of the data.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    public func json(urlRequest: URLRequest, completionHandler: CompletionClosure?) -> URLSessionDataTask {
        let dataTask = urlSession.jsonTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                switch (error as NSError).code {
                case NSURLErrorCancelled:
                    completionHandler?(.failure(NetworkControllerError.cancelled))
                default:
                    completionHandler?(.failure(error))
                }
                return
            }
            
            guard let response = response else {
                completionHandler?(.failure(NetworkControllerError.invalidResponse))
                return
            }
            
            completionHandler?(.success(.init(httpURLResponse: response, data: data)))
        }
        dataTask.resume()
        return dataTask
    }
}
