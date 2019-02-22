//
//  Connection+URLGeneration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension Connection {
    
    struct Constants {
        static let url = URL(string: "https://ifttt.com/access/api")!
        
        struct QueryItem {
            static let sdkReturnName = "sdk_return_to"
            static let inviteCodeName = "invite_code"
            static let emailName = "email"
            static let skipSDKRedirectName = "skip_sdk_redirect"
            static let sdkCreatAccountName = "sdk_create_account"
            static let oauthCodeName = "code"
            static let defaultTrueValue = "true"
            static let sdkVersionName = "sdk_version"
            static let sdkPlatformName = "sdk_platform"
        }
    }
    
    enum ActivationStep {
        case
        login(User.Id),
        serviceConnection(newUserEmail: String?)
        
        fileprivate var shouldAppendOAuthCode: Bool {
            switch self {
            case .login:
                return true
            case .serviceConnection(let newUserEmail):
                return newUserEmail?.isEmpty == false
            }
        }
    }
    
    /// The activation url is formed by appending the Connection's ID
    private var activationURL: URL {
        return Constants.url.appendingPathComponent(id)
    }
    
    func activationURL(for step: ActivationStep, credentialProvider: CredentialProvider, activationRedirect: URL) -> URL {
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems(for: step, credentialProvider: credentialProvider, activationRedirect: activationRedirect)
       
        // We need to manually encode `+` characters in a user's e-mail because `+` is a valid character that represents a space in a url query. E-mail's with spaces are not valid.
        let percentEncodedQuery = components?.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: .emailEncodingPassthrough)
        components?.percentEncodedQuery = percentEncodedQuery
        
        return components?.url ?? activationURL
    }
    
    private func queryItems(for step: ActivationStep, credentialProvider: CredentialProvider, activationRedirect: URL) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: Constants.QueryItem.sdkReturnName, value: activationRedirect.absoluteString),
                          URLQueryItem(name: Constants.QueryItem.sdkVersionName, value: API.sdkVersion),
                          URLQueryItem(name: Constants.QueryItem.sdkPlatformName, value: API.sdkPlatform)]
        
        if let inviteCode = credentialProvider.inviteCode {
            queryItems.append(URLQueryItem(name: Constants.QueryItem.inviteCodeName, value: inviteCode))
        }
        
        switch step {
        case let .login(userId):
            queryItems.append(queryItemForLogin(userId: userId))
        case let .serviceConnection(userEmail):
            queryItems.append(contentsOf: queryItemsforServiceConnection(userEmail: userEmail))
        }
        
        if step.shouldAppendOAuthCode, let item = queryItemForPartnerOauthCode(code: credentialProvider.partnerOAuthCode) {
            queryItems.append(item)
        }
        
        return queryItems
    }
    
    private func queryItemForLogin( userId: User.Id) -> URLQueryItem {
        return URLQueryItem(name: Constants.QueryItem.emailName, value: userId.value)
    }
    
    private func queryItemsforServiceConnection(userEmail: String?) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: Constants.QueryItem.skipSDKRedirectName, value: Constants.QueryItem.defaultTrueValue)]
        
        if let email = userEmail {
            queryItems.append(URLQueryItem(name: Constants.QueryItem.emailName, value: email))
            queryItems.append(URLQueryItem(name: Constants.QueryItem.sdkCreatAccountName, value: Constants.QueryItem.defaultTrueValue))
        }
        
        return queryItems
    }
    
    private func queryItemForPartnerOauthCode(code: String) -> URLQueryItem? {
        guard !code.isEmpty else {
            return nil
        }
        return URLQueryItem(name: Constants.QueryItem.oauthCodeName, value: code)
    }
}

extension CharacterSet {
    
    /// This allows '+' character to passthrough for sending an email address as a url parameter.
    static let emailEncodingPassthrough = CharacterSet(charactersIn: "+").inverted
}
