//
//  WebServiceAuthentication.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import AuthenticationServices

/// Describes the error reason for a failed `WebServiceAuthentication`
///
/// - userCanceled: The user cancelled the authentication session.
/// - failed: The authentication failed for some reason.
/// - invalidResponse: The response returned by the web service was invalid.
/// - notHandled: The error wasn't handled by the web service.
/// - presentationContextInvalid: The presentation content provided was invalid.
/// - unknown: Some unknown error ocurred when authenticating with the web service.
enum AuthenticationError: Error {
    case userCanceled
    case failed
    case invalidResponse
    case notHandled
    case presentationContextInvalid
    case unknown
}

/// Describes a generic method of authenticating with a service
protocol ServiceAuthentication {
    /// The parameters to pass to authenticate with the service
    associatedtype Parameters
    /// The object type on a successful service authentication
    associatedtype Completion
    /// THe error type on a non-successful service authentication
    associatedtype ErrorType: Error
    
    /// Describes a closure that gets invoked on success/failure of a service authentication
    typealias AuthenticationSessionClosure = ((Result<Completion, ErrorType>) -> Void)
    
    /// Starts the service authentication.
    /// - Parameters:
    ///     - parameters: An instance of `Parameters` which can be used in authenticating against the service.
    ///     - completionHandler: The closure to invoke on a success or failure response from the service.
    /// - Returns: A `Bool` value as to whether or not the service authentication was started or not.
    func start(with parameters: Parameters, completionHandler: @escaping AuthenticationSessionClosure) -> Bool
    
    /// Cancels the service authentication.
    func cancel()
}

/// A basic OAuth web service authentication object.
class WebServiceAuthentication: ServiceAuthentication {
    
    /// The parameters used when authenticating against a web service
    struct WebServiceAuthenticationParameters {
        /// The URL to use in authenticating the service
        let url: URL
        /// The callback url scheme which the service uses to pass back any data
        let callbackURLScheme: String?
        /// Determines whether or not the session should be ephemeral or not. Not all service authentication types support this
        let prefersEphemeralWebBrowserSession: Bool
    }

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

