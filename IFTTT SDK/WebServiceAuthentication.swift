//
//  WebServiceAuthentication.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import AuthenticationServices

/// Describes the error reason for a failed `AuthenticationSession`
///
/// - userCanceled: The user cancelled the authentication session
/// - 
enum AuthenticationError: Error {
    case userCanceled
    case failed
    case invalidResponse
    case notHandled
    case presentationContextInvalid
    case unknown
}

protocol ServiceAuthentication {
    associatedtype Parameters
    associatedtype Completion
    associatedtype ErrorType: Error
    
    typealias AuthenticationSessionClosure = ((Result<Completion, ErrorType>) -> Void)
    
    func start(with parameters: Parameters, completionHandler: @escaping AuthenticationSessionClosure) -> Bool
    func cancel()
}

class WebServiceAuthentication: ServiceAuthentication {
    typealias Parameters = WebServiceAuthenticationParameters
    typealias Completion = URL
    typealias ErrorType = AuthenticationError
    
    @discardableResult
    func start(with parameters: Parameters, completionHandler: @escaping AuthenticationSessionClosure) -> Bool {
        fatalError("This class must be subclassed.")
    }
    
    func cancel() {
        fatalError("This class must be subclassed.")
    }
}

struct WebServiceAuthenticationParameters {
    let url: URL
    let callbackURLScheme: String?
    let prefersEphemeralWebBrowserSession: Bool
}
