//
//  TokenRequest.swift
//  Grocery Express
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// Request the IFTTT service token for the current user
/// If the user has already connected Grocery Token, this will grant the service token
struct TokenRequest {
    private let credentials: ConnectionCredentials
    private let urlRequest: URLRequest
    
    /// Make the request
    ///
    /// - Parameter completion: Returns the updated credentials
    func start(_ completion: ((ConnectionCredentials) -> Void)? = nil) {
        let credentials = self.credentials
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, _) in
            if let data = data,
                let response = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??),
                let token = response?["user_token"] as? String {
                
                credentials.loginUser(with: token)
            }
            DispatchQueue.main.async {
                completion?(credentials)
            }
        }
        task.resume()
    }
    
    /// Creates a `TokenRequest`
    ///
    /// - Parameter credentials: The credentials used to fetch the token
    init(credentials: ConnectionCredentials) {
        self.credentials = credentials
        self.urlRequest = TokenRequest.tokenURLRequest(for: credentials)
    }
    
    private static func tokenURLRequest(for credentials: ConnectionCredentials) -> URLRequest {
        var components = URLComponents(string: "https://grocery-express.ifttt.com/api/user_token")!
        components.queryItems = [URLQueryItem(name: "code", value: credentials.oauthCode)]
        
        // For the Grocery Express service we use the email as the oauth code
        // We need to manually encode `+` characters in a user's e-mail because `+` is a valid character that represents a space in a url query. E-mail's with spaces are not valid.
        let percentEncodedQuery = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: .emailEncodingPassthrough)
        components.percentEncodedQuery = percentEncodedQuery
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        return request
    }
}

private extension CharacterSet {
    
    /// This allows '+' character to passthrough for sending an email address as a url parameter.
    static let emailEncodingPassthrough = CharacterSet(charactersIn: "+").inverted
}

