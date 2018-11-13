//
//  URLSession+JSONTask.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

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
    
    func jsonTask(with urlRequest: URLRequest, waitUntil minimumDuration: TimeInterval, _ completion: @escaping (Parser, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        var result: (Parser, HTTPURLResponse?, Error?)?
        var minimumTimeElapsed = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDuration) {
            minimumTimeElapsed = true
            if let result = result {
                completion(result.0, result.1, result.2)
            }
        }
        
        return jsonTask(with: urlRequest) { (parser, response, error) in
            if minimumTimeElapsed {
                completion(parser, response, error)
            } else {
                result = (parser, response, error)
            }
        }
    }
}
