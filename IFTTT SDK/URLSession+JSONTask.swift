//
//  URLSession+JSONTask.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

// FIXME: Not public

import Foundation

extension URLSession {
    
    static let connectionURLSession: URLSession =  {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["Accept" : "application/json"]
        return URLSession(configuration: configuration)
    }()
    
    func jsonTask(with urlRequest: URLRequest, _ completion: @escaping (Parser, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async {
                completion(Parser(content: data), response as? HTTPURLResponse, error)
            }
        }
    }
}
