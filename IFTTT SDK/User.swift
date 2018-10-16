//
//  User.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

public struct User {
    public static var current = User()
    
    public var suggestedUserEmail: String?
}

extension User {
    static func check(email: String, timeout: TimeInterval, _ completion: @escaping ((Bool) -> Void)) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        let urlSession = URLSession(configuration: configuration)
        
        let url = URL(string: "https://api.ifttt.com/v2/account/find?email=\(email)")!
        urlSession.dataTask(with: url) { (_, response, _) in
            if let response = response as? HTTPURLResponse {
                completion(response.statusCode == 204)
            } else {
                completion(true) // Assume account exists if something goes wrong
            }
        }
        .resume()
    }
}
