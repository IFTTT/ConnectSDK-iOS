//
//  ConnectionActivationFlow.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// A model holding links to portions of the connection handoff flow which happens on web or in the IFTTT app
struct ConnectionHandoffFlow {
    
    /// The URL for the deeplinking to the connection in the IFTTT app or nil if the app is not installed
    private let baseAppHandoffUrl: URL
    
    /// Returns true if the IFTTT app is installed and support handoff from the SDK
    var isAppHandoffAvailable: Bool {
        return UIApplication.shared.canOpenURL(baseAppHandoffUrl)
    }
    
    /// Creates the URL to handoff the connection activation flow to the IFTTT app
    ///
    /// - Parameter userId: The current User or nil if there isn't one
    /// - Parameter action: The action to perform after the handoff occurs
    /// - Returns: The URL to open handoff in the IFTTT app or nil if handoff cannot be done
    func appHandoffUrl(userId: User.Id?, action: ConnectionDeeplinkAction = .activation) -> URL? {
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
        queryItems.append(URLQueryItem(name: Constants.QueryItem.actionName, value: action.rawValue))
        urlComponents.queryItems = queryItems
        
        return urlComponents.fixingEmailEncoding().url
    }
    
    /// The URL to complete a Connection activate in Safari
    ///
    /// - Parameter user: The current User
    /// - Returns: The URL to open in Safari
    func webFlowUrl(user: User) -> URL {
        guard var urlComponents = URLComponents(url: handoffURL, resolvingAgainstBaseURL: false) else {
            return handoffURL
        }
        var queryItems = commonQueryItems
        
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
        
        return urlComponents.fixingEmailEncoding().url ?? handoffURL
    }
    
    private let commonQueryItems: [URLQueryItem]
    private let partnerOauthCodeQueryItem: URLQueryItem?
    private let inviteCodeQueryItem: URLQueryItem?
    
    private let handoffURL: URL
    
    /// Creates a `ConnectionHandoffFlow`
    /// Generates URLs for activating a Connection in web or the IFTTT app
    ///
    /// - Parameters:
    ///   - connectionId: The identifier of the Connection to activate
    ///   - credentialProvider: A `CredentialProvider` for the user
    ///   - activationRedirect: The redirect back to this application
    ///   - skipConnectionConfiguration: A `Bool` that is used to skip the configuration of the Connection when it's activated in either the IFTTT app or the web flow.
    init(connectionId: String,
         credentialProvider: ConnectionCredentialProvider,
         activationRedirect: URL,
         skipConnectionConfiguration: Bool) {
        
        handoffURL = Constants.url.appendingPathComponent(connectionId)
        
        // Creates the query items shared by all URLs
        var commonQueryItems =  [
            URLQueryItem(name: Constants.QueryItem.sdkReturnName, value: activationRedirect.absoluteString),
            URLQueryItem(name: Constants.QueryItem.sdkVersionName, value: API.sdkVersion),
            URLQueryItem(name: Constants.QueryItem.sdkPlatformName, value: API.sdkPlatform),
            URLQueryItem(name: Constants.QueryItem.sdkAnonymousId, value: API.anonymousId),
            URLQueryItem(name: Constants.QueryItem.sdkLocale, value: ConnectButtonController.locale.identifier)
        ]
        
        if skipConnectionConfiguration {
            commonQueryItems.append(URLQueryItem(name: Constants.QueryItem.sdkSkipConnectionConfiguration, value: "true"))
        }
        
        let partnerOauthCodeQueryItem: URLQueryItem?
        if !credentialProvider.oauthCode.isEmpty {
            partnerOauthCodeQueryItem = URLQueryItem(name: Constants.QueryItem.oauthCodeName,
                                                     value: credentialProvider.oauthCode)
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
            static let actionName = "action"
            static let editValue = "edit"
            static let activationValue = "activation"
            static let sdkLocale = "locale"
            
            static let sdkReturnName = "sdk_return_to"
            static let inviteCodeName = "invite_code"
            static let emailName = "email"
            static let username = "username"
            static let sdkCreateAccountName = "sdk_create_account"
            static let oauthCodeName = "code"
            static let defaultTrueValue = "true"
            static let sdkVersionName = "sdk_version"
            static let sdkPlatformName = "sdk_platform"
            static let sdkAnonymousId = "sdk_anonymous_id"
            static let sdkSkipConnectionConfiguration = "skip_config"
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
