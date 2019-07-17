//
//  Connection+Request.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

public extension Connection {
    
    /// Handles network requests related to the `Connection`.
    struct Request {
        
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
        public static func fetchConnection(for id: String, credentialProvider: ConnectionCredentialProvider) -> Request {
            return Request(path: "/connections/\(id)", method: .GET, credentialProvider: credentialProvider)
        }
        
        /// A disconnection `Request` for a `Connection` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Connection`.
        ///   - credentialProvider: An object that handle providing credentials for a request.
        /// - Returns:  A `Request` configured to disconnect the `Connection`.
        public static func disconnectConnection(with id: String, credentialProvider: ConnectionCredentialProvider) -> Request {
            return Request(path: "/connections/\(id)/disable", method: .POST, credentialProvider: credentialProvider)
        }
        
        private init(path: String, method: Method, credentialProvider: ConnectionCredentialProvider) {
            let url = API.base.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = credentialProvider.userToken, userToken.isEmpty == false {
                request.addIftttServiceToken(userToken)
            }
            
            if let inviteCode = credentialProvider.inviteCode, inviteCode.isEmpty == false {
                request.addIftttInviteCode(inviteCode)
            }
            request.addVersionTracking()
            
            self.urlRequest = request
        }
    }
}
