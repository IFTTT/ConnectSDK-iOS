//
//  TokenRequest.swift
//  Grocery Express
//
//  Created by Jon Chmura on 1/3/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

struct TokenRequest {
    /// Requests the IFTTT service token for Grocery Express from a Grocery Express API which using a combination of its service key and oauth code to identify the linked IFTTT account
    static func getIFTTTServiceToken(for oauthCode: String, _ completion: @escaping (String?) -> Void) {
        var components = URLComponents(string: "https://grocery-express.ifttt.com/api/user_token")!
        components.queryItems = [URLQueryItem(name: "code", value: oauthCode)]
        
        // For the Grocery Express service we use the email as the oauth code
        // We need to manually encode `+` characters in a user's e-mail because `+` is a valid character that represents a space in a url query. E-mail's with spaces are not valid.
        let percentEncodedQuery = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: .emailEncodingPassthrough)
        components.percentEncodedQuery = percentEncodedQuery
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            if let data = data, let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let token = response?["user_token"] as? String {
                DispatchQueue.main.async {
                    completion(token)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

private extension CharacterSet {
    
    /// This allows '+' character to passthrough for sending an email address as a url parameter.
    static let emailEncodingPassthrough = CharacterSet(charactersIn: "+").inverted
}
