//
//  Connection+URLGeneration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    
    private enum URLQueryItemConstants {
        static let sdkReturnName = "sdk_return_to"
        static let inviteCodeName = "invite_code"
        static let emailName = "email"
        static let skipSDKRedirectName = "skip_sdk_redirect"
        static let sdkCreatAccountName = "sdk_create_account"
        static let tokenName = "code"
        static let defaultTrueValue = "true"
        static let sdkVersionName = "sdk_version"
        static let sdkPlatformName = "sdk_platform"
    }
    
    enum ActivationStep {
        case
        login(User.Id),
        serviceConnection(newUserEmail: String?, token: String?)
    }
    
    func activationURL(for step: ActivationStep, tokenProvider: CredentialProvider, activationRedirect: URL) -> URL {
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems(for: step, tokenProvider: tokenProvider, activationRedirect: activationRedirect)
        return components?.url ?? activationURL
    }
    
    private func queryItems(for step: ActivationStep, tokenProvider: CredentialProvider, activationRedirect: URL) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: URLQueryItemConstants.sdkReturnName, value: activationRedirect.absoluteString),
                          URLQueryItem(name: URLQueryItemConstants.sdkVersionName, value: API.sdkVersion),
                          URLQueryItem(name: URLQueryItemConstants.sdkPlatformName, value: API.sdkPlatform)]
        
        if let inviteCode = tokenProvider.inviteCode {
            queryItems.append(URLQueryItem(name: URLQueryItemConstants.inviteCodeName, value: inviteCode))
        }
        
        switch step {
        case let .login(userId):
            queryItems.append(queryItemForLogin(userId: userId))
        case let .serviceConnection(userEmail, token):
            queryItems.append(contentsOf: queryItemsforServiceConnection(userEmail: userEmail, token: token))
        }
        
        return queryItems
    }
    
    private func queryItemForLogin( userId: User.Id) -> URLQueryItem {
        return URLQueryItem(name: URLQueryItemConstants.emailName, value: userId.value)
    }
    
    private func queryItemsforServiceConnection(userEmail: String?, token: String?) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: URLQueryItemConstants.skipSDKRedirectName, value: URLQueryItemConstants.defaultTrueValue)]
        
        if let email = userEmail {
            queryItems.append(URLQueryItem(name: URLQueryItemConstants.emailName, value: email))
            queryItems.append(URLQueryItem(name: URLQueryItemConstants.sdkCreatAccountName, value: URLQueryItemConstants.defaultTrueValue))
        }
        
        if let token = token {
            queryItems.append(URLQueryItem(name: URLQueryItemConstants.tokenName, value: token))
        }
        
        return queryItems
    }
}
