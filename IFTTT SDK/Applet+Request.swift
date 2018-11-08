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

        /// A `Request` configured for an `Applet` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Applet`.
        ///   - completion: A `CompletionHandler` for handling the result of the request.
        /// - Returns: A `Request` configured to get the `Applet`.
        public static func applet(id: String, iftttServiceToken: String?, inviteCode: String?) -> URLRequest {
            return Request(path: "/applets/\(id)", method: .GET, iftttServiceToken: iftttServiceToken, inviteCode: inviteCode).urlRequest
        }
        
        /// A disconnection `Request` for an `Applet` with the provided identifier.
        ///
        /// - Parameters:
        ///   - id: The identifier of the `Applet`.
        ///   - completion: A `CompletionHandler` for handling the result of the request.
        /// - Returns: A `Request` configured to disconnect the `Applet`.
        public static func disconnectApplet(id: String, iftttServiceToken: String?, inviteCode: String?) -> Request {
            return Request(path: "/applets/\(id)/disable)", method: .POST, iftttServiceToken: iftttServiceToken, inviteCode: inviteCode)
        }
        
        private init(path: String, method: Method, iftttServiceToken: String?, inviteCode: String?) {
            let url = API.base.appendingPathComponent(path)
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let userToken = iftttServiceToken, userToken.isEmpty == false {
                request.addIftttUserToken(userToken)
            }
            
            if let inviteCode = inviteCode, inviteCode.isEmpty == false {
                request.addIftttInviteCode(inviteCode)
            }
            
            self.urlRequest = request
        }
    }
}
