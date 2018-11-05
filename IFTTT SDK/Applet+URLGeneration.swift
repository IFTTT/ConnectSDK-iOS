//
//  Applet+URLGeneration.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/5/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

extension Applet {
    
    enum ActivationStep {
        case
        login(User.Id),
        serviceConnection(newUserEmail: String?, token: String?)
    }
    
    func activationURL(for step: ActivationStep) -> URL {
        let session = Applet.Session.shared
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems(for: step, with: session)
        return components?.url ?? activationURL
    }
    
    private func queryItems(for step: ActivationStep, with session: Applet.Session) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: "sdk_return_to", value: session.appletActivationRedirect.absoluteString)]
        
        if let inviteCode = session.inviteCode {
            queryItems.append(URLQueryItem(name: "invite_code", value: inviteCode))
        }
        
        switch step {
        case let .login(userId):
            queryItems.append(queryItem(forLogin: userId))
        case let .serviceConnection(userEmail, token):
            queryItems.append(contentsOf: queryItemsforServiceConnection(userEmail: userEmail, token: token))
        }
        
        return queryItems
    }
    
    private func queryItem(forLogin userId: User.Id) -> URLQueryItem {
        switch userId {
        case let .username(username):
            // FIXME: Verify this param name when we have it
            return URLQueryItem(name: "user_id", value: username)
        case let .email(email):
            return URLQueryItem(name: "email", value: email)
        }
    }
    
    private func queryItemsforServiceConnection(userEmail: String?, token: String?) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: "skip_sdk_redirect", value: "true")]
        
        if let email = userEmail {
            queryItems.append(URLQueryItem(name: "email", value: email))
            queryItems.append(URLQueryItem(name: "sdk_create_account", value: "true"))
        }
        
        if let token = token {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        
        return queryItems
    }
}
