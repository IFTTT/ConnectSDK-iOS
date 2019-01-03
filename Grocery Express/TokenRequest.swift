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
        var request = URLRequest(url: URL(string: "https://grocery-express.ifttt.com/api/user_token?code=\(oauthCode)")!)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            if let data = data, let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let token = response?["user_token"] as? String {
                completion(token)
            } else {
                completion(nil)
            }
        }
    }
}
