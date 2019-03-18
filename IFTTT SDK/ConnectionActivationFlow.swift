//
//  ConnectionActivationFlow.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 3/12/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// A model holding links to portions of the connection flow which happens on web or in the IFTTT app
struct ConnectionActivationFlow {
    
    /// The URL for the deeplinking to the connection in the IFTTT app or nil if the app is not installed
    private let appHandoffUrl: URL?
    
    /// Returns true if the IFTTT app is installed
    var isAppHandoffAvailable: Bool {
        return appHandoffUrl != nil
    }
    
    /// Launch the IFTTT app to complete the connection activation flow
    func performAppHandoff() {
        guard let url = appHandoffUrl else { return }
        UIApplication.shared.openURL(url)
    }
    
    /// The URL to log the user in on Safari
    ///
    /// - Parameter userId: The identifier for the user
    /// - Returns: The URL to open in Safari
    func loginUrl(userId: User.Id) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var queryItems = commonQueryItems
        
        queryItems.append(URLQueryItem(name: Constants.QueryItem.emailName, value: userId.value))
        if let oauthItem = partnerOauthCodeQueryItem {
            queryItems.append(oauthItem)
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.fixingEmailEncoding().url ?? url
    }
    
    /// The URL to connect a service and complete the flow in Safari
    ///
    /// - Parameter newUserEmail: For the new user flow send the user email, otherwise send nil
    /// - Returns: The URL to open in Safari
    func serviceConnectionUrl(newUserEmail: String?) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var queryItems = commonQueryItems
        
        queryItems.append(URLQueryItem(name: Constants.QueryItem.skipSDKRedirectName, value: Constants.QueryItem.defaultTrueValue))
        
        if let email = newUserEmail {
            queryItems.append(URLQueryItem(name: Constants.QueryItem.emailName, value: email))
            queryItems.append(URLQueryItem(name: Constants.QueryItem.sdkCreatAccountName, value: Constants.QueryItem.defaultTrueValue))
            if let oauthItem = partnerOauthCodeQueryItem {
                queryItems.append(oauthItem)
            }
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.fixingEmailEncoding().url ?? url
    }
    
    private let commonQueryItems: [URLQueryItem]
    private let partnerOauthCodeQueryItem: URLQueryItem?
    private let inviteCodeQueryItem: URLQueryItem?
    
    private let url: URL
    
    /// Creates a `ConnectionActivationFlow`
    /// Generates URLs for activating a Connection in web or the IFTTT app
    ///
    /// - Parameters:
    ///   - connectionId: The identifier of the Connection to activate
    ///   - credentialProvider: A `CredentialProvider` for the user
    ///   - activationRedirect: The redirect back to this application
    init(connectionId: String,
         credentialProvider: CredentialProvider,
         activationRedirect: URL) {
        
        url = Constants.url.appendingPathComponent(connectionId)
        
        // Creates the query items shared by all URLs
        let commonQueryItems =  [
            URLQueryItem(name: Constants.QueryItem.sdkReturnName, value: activationRedirect.absoluteString),
            URLQueryItem(name: Constants.QueryItem.sdkVersionName, value: API.sdkVersion),
            URLQueryItem(name: Constants.QueryItem.sdkPlatformName, value: API.sdkPlatform),
            URLQueryItem(name: Constants.QueryItem.sdkAnonymousId, value: API.anonymousId)]
        
        let partnerOauthCodeQueryItem: URLQueryItem?
        if !credentialProvider.partnerOAuthCode.isEmpty {
            partnerOauthCodeQueryItem = URLQueryItem(name: Constants.QueryItem.oauthCodeName,
                                                     value: credentialProvider.partnerOAuthCode)
        } else {
            partnerOauthCodeQueryItem = nil
        }
        
        if let inviteCode = credentialProvider.inviteCode {
            inviteCodeQueryItem = URLQueryItem(name: Constants.QueryItem.inviteCodeName,
                                               value: inviteCode)
        } else {
            inviteCodeQueryItem = nil
        }
        
        self.commonQueryItems = commonQueryItems
        self.partnerOauthCodeQueryItem = partnerOauthCodeQueryItem
        appHandoffUrl = {
            let url = Constants.appHandoffURL.appendingPathComponent(connectionId)
            guard UIApplication.shared.canOpenURL(url),
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return nil
            }
            urlComponents.queryItems = commonQueryItems
            if let oauthCodeItem = partnerOauthCodeQueryItem {
                urlComponents.queryItems!.append(oauthCodeItem)
            }
            return urlComponents.url
        }()
    }
    
    struct Constants {
        static let appHandoffURL = URL(string: "ifttt-handoff-v1://connections")!
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
            static let sdkAnonymousId = "sdk_anonymous_id"
        }
    }
}
