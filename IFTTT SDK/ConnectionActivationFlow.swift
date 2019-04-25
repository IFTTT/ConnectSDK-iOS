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
    private let baseAppHandoffUrl: URL
    
    /// Returns true if the IFTTT app is installed and support handoff from the SDK
    var isAppHandoffAvailable: Bool {
        return UIApplication.shared.canOpenURL(baseAppHandoffUrl)
    }
    
    /// Creates the URL to handoff the connection activation flow to the IFTTT app
    ///
    /// - Parameter userId: The current User or nil if there isn't one
    /// - Returns: The URL to open handoff in the IFTTT app or nil if handoff cannot be done
    func appHandoffUrl(userId: User.Id?) -> URL? {
        guard
            UIApplication.shared.canOpenURL(baseAppHandoffUrl),
            var urlComponents = URLComponents(url: baseAppHandoffUrl,
                                                resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = commonQueryItems
        if let oauthCodeItem = partnerOauthCodeQueryItem {
            queryItems.append(oauthCodeItem)
        }
        if let userId = userId {
            queryItems.append(userQueryItem(for: userId))
        }
        urlComponents.queryItems = queryItems
        
        return urlComponents.fixingEmailEncoding().url
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
        
        queryItems.append(userQueryItem(for: userId))
        
        queryItems.append(contentsOf: queryItemsForAvailableEmailClients())
        
        if let oauthItem = partnerOauthCodeQueryItem {
            queryItems.append(oauthItem)
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.fixingEmailEncoding().url ?? url
    }
    
    /// The URL to connect a service and complete the flow in Safari
    ///
    /// - Parameter user: The current User
    /// - Returns: The URL to open in Safari
    func serviceConnectionUrl(user: User) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var queryItems = commonQueryItems
        
        queryItems.append(URLQueryItem(name: Constants.QueryItem.skipSDKRedirectName, value: Constants.QueryItem.defaultTrueValue))
        
        queryItems.append(userQueryItem(for: user.id))
        
        if !user.isExistingUser { // New user
            queryItems.append(URLQueryItem(name: Constants.QueryItem.sdkCreateAccountName, value: Constants.QueryItem.defaultTrueValue))
        } else { // Returning user
            queryItems.append(contentsOf: queryItemsForAvailableEmailClients())
        }
        
        if let oauthItem = partnerOauthCodeQueryItem {
            queryItems.append(oauthItem)
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
        baseAppHandoffUrl = Constants.appHandoffURL.appendingPathComponent(connectionId)
    }
    
    /// Checks for available email clients on the device
    /// This enables us to give the user a list of options to complete email verfication in the returning user flow
    ///
    /// - Returns: A list of `URLQueryItem`s for available email clients
    private func queryItemsForAvailableEmailClients() -> [URLQueryItem] {
        return EmailClientSchemes.all.compactMap {
            if UIApplication.shared.canOpenURL($0.url) {
                return URLQueryItem(name: Constants.QueryItem.availableEmailScheme,
                                    value: $0.rawValue)
            } else {
                return nil
            }
        }
    }
    
    private func userQueryItem(for userId: User.Id) -> URLQueryItem {
        switch userId {
        case .email(let email):
            return URLQueryItem(name: Constants.QueryItem.emailName, value: email)
        case .username(let username):
            return URLQueryItem(name: Constants.QueryItem.username, value: username)
        }
    }
    
    private struct Constants {
        static let appHandoffURL = URL(string: "\(API.iftttAppScheme)connections")!
        static let url = URL(string: "https://ifttt.com/access/api")!
        
        struct QueryItem {
            static let sdkReturnName = "sdk_return_to"
            static let inviteCodeName = "invite_code"
            static let emailName = "email"
            static let username = "username"
            static let skipSDKRedirectName = "skip_sdk_redirect"
            static let sdkCreateAccountName = "sdk_create_account"
            static let oauthCodeName = "code"
            static let defaultTrueValue = "true"
            static let sdkVersionName = "sdk_version"
            static let sdkPlatformName = "sdk_platform"
            static let sdkAnonymousId = "sdk_anonymous_id"
            static let availableEmailScheme = "available_email_app_schemes[]"
        }
    }
    
    private enum EmailClientSchemes: String {
        static let all: [EmailClientSchemes] = [.mail, .gmail, .outlook, .yahoo, .airmail, .spark]
        
        case mail = "message://"
        case gmail = "googlegmail://"
        case outlook = "ms-outlook://"
        case yahoo = "ymail://"
        case airmail = "airmail://"
        case spark = "readdle-spark://"
        
        var url: URL {
            return URL(string: rawValue)!
        }
    }
}
