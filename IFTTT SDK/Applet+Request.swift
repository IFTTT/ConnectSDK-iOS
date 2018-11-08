//
//  Applet+Request.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public extension Applet {
    
    /// Handles network requests related to the `Connection`.
    public struct Request {
        
        /// The HTTP request method options.
        enum Method: String {
            
            /// The HTTP GET method.
            case GET = "GET"
            
            /// The HTTP POST method.
            case POST = "POST"
        }
        
        /// The `Request`'s `URLRequest` that task are completed on.
        public let urlRequest: URLRequest
        
        /// A `Request` configured to get a `Connection` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Connection`.
        ///   - tokenProvider: An object that handle providing tokens for a request.
        /// - Returns: A `Request` configured to get the `Connection`.
        public static func fetchConnection(for id: String, tokenProvider: TokenProviding) -> Request {
            return Request(path: "/applets/\(id)", method: .GET, tokenProvider: tokenProvider)
        }
        
        /// A disconnection `Request` for a `Connection` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Connection`.
        ///   - tokenProvider: An object that handle providing tokens for a request.
        /// - Returns:  A `Request` configured to disconnect the `Connection`.
        public static func disconnectConnection(with id: String, tokenProvider: TokenProviding) -> Request {
            return Request(path: "/applets/\(id)/disable)", method: .POST, tokenProvider: tokenProvider)
        }
        
        private init(path: String, method: Method, tokenProvider: TokenProviding) {
            let url = API.base.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = tokenProvider.iftttServiceToken, userToken.isEmpty == false {
                request.addIftttUserToken(userToken)
            }
            
            if let inviteCode = tokenProvider.inviteCode, inviteCode.isEmpty == false {
                request.addIftttInviteCode(inviteCode)
            }
            
            self.urlRequest = request
        }
    }
}
