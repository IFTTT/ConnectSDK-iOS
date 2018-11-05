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
    
    func activationURL(_ step: ActivationStep) -> URL {
        let session = Applet.Session.shared
        
        var components = URLComponents(url: activationURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "sdk_return_to", value: session.appletActivationRedirect.absoluteString))
        
        if let inviteCode = session.inviteCode {
            queryItems.append(URLQueryItem(name: "invite_code", value: inviteCode))
        }
        
        switch step {
        case .login(let id):
            switch id {
            case .username(let username):
                // FIXME: Verify this param name when we have it
                queryItems.append(URLQueryItem(name: "user_id", value: username))
            case .email(let email):
                queryItems.append(URLQueryItem(name: "email", value: email))
            }
            
        case .serviceConnection(let newUserEmail, let token):
            if let email = newUserEmail {
                queryItems.append(URLQueryItem(name: "email", value: email))
                queryItems.append(URLQueryItem(name: "sdk_create_account", value: "true"))
            }
            if let token = token {
                queryItems.append(URLQueryItem(name: "token", value: token))
            }
            queryItems.append(URLQueryItem(name: "skip_sdk_redirect", value: "true"))
        }
        components?.queryItems = queryItems
        return components?.url ?? activationURL
    }
}
