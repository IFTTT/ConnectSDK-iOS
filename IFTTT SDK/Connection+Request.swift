//
//  Connection+Request.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public extension Connection {
    
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
        ///   - credentialProvider: An object that handle providing credentials for a request.
        /// - Returns: A `Request` configured to get the `Connection`.
        public static func fetchConnection(for id: String, credentialProvider: CredentialProvider) -> Request {
            return Request(path: "/connections/\(id)", method: .GET, credentialProvider: credentialProvider)
        }
        
        /// A disconnection `Request` for a `Connection` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Connection`.
        ///   - credentialProvider: An object that handle providing credentials for a request.
        /// - Returns:  A `Request` configured to disconnect the `Connection`.
        public static func disconnectConnection(with id: String, credentialProvider: CredentialProvider) -> Request {
            return Request(path: "/connections/\(id)/disable", method: .POST, credentialProvider: credentialProvider)
        }
        
        private init(path: String, method: Method, credentialProvider: CredentialProvider) {
            let url = API.base.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = credentialProvider.iftttServiceToken, userToken.isEmpty == false {
                request.addIftttServiceToken(userToken)
            }
            
            if let inviteCode = credentialProvider.inviteCode, inviteCode.isEmpty == false {
                request.addIftttInviteCode(inviteCode)
            }
            
            self.urlRequest = request
        }
    }
}
