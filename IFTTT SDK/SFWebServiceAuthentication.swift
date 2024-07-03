//
//  SFWebServiceAuthentication.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import SafariServices

/// Wraps an `SFAuthenticationSession`. Used to authenticate web services up to (not including) iOS 12.
@available(iOS 11.0, *)
final class SFWebService: WebServiceAuthentication {

    /// The backing `SFAuthenticationSession` object.
    private var session: SFAuthenticationSession?
    
    @discardableResult
    override func start(with parameters: Parameters, completionHandler: @escaping (Result<URL, AuthenticationError>) -> Void) -> Bool {
        let sfAuthenticationSession = SFAuthenticationSession(url: parameters.url,
                                                              callbackURLScheme: parameters.callbackURLScheme) { url, error in
            guard error == nil, let url = url else {
                completionHandler(.failure(.userCanceled))
                return
            }
            completionHandler(.success(url))
        }
        self.session = sfAuthenticationSession
        return sfAuthenticationSession.start()
    }
    
    override func cancel() {
        session?.cancel()
    }
}
