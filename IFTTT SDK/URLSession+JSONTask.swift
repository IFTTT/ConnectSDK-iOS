//
//  URLSession+JSONTask.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
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
}
