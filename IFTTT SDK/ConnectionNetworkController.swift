//
//  ConnectionNetworkController.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/8/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

final class ConnectionNetworkController {
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .connectionURLSession) {
        self.urlSession = urlSession
    }
    
    private enum APIConstants {
        static let userLoginKey = "user_login"
    }
    
    func getConnectConfiguration(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        checkUser(user: user, waitUntil: waitUntil, timeout: timeout) { configuration, error in
            DispatchQueue.main.async {
                completion(configuration, error)
            }
        }
    }
    
    private func checkUser(user: ConnectConfiguration.UserLookupMethod, waitUntil: TimeInterval, timeout: TimeInterval, _ completion: @escaping (ConnectConfiguration?, Error?) -> Void) {
        switch user {
        case .email(let email):
            urlSession.jsonTask(with: makeFindUserByEmailRequest(with: email, timeout: timeout), waitUntil: waitUntil) { _, response, error in
                let configuration = ConnectConfiguration(isExistingUser: response?.statusCode == 204, userId: .email(email))
                completion(configuration, error)
                }.resume()
        case .token(let token):
            urlSession.jsonTask(with: makeFindUserByTokenRequest(with: token, timeout: timeout), waitUntil: waitUntil) { parser, _, error in
                guard let username = parser[APIConstants.userLoginKey].string else {
                    completion(nil, error)
                    return
                }
                
                let configuration = ConnectConfiguration(isExistingUser: false, userId: .username(username))
                completion(configuration, error)
                }.resume()
        }
    }
    
    private func makeFindUserByEmailRequest(with email: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserBy(email: email))
        request.timeoutInterval = timeout
        return request
    }
    
    private func makeFindUserByTokenRequest(with token: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: API.findUserByToken)
        request.addIftttUserToken(token)
        request.timeoutInterval = timeout
        return request
    }
}
