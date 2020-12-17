//
//  ConnectionNetworkError.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// An error occurred, preventing the network controller from completing network requests.
public enum NetworkControllerError: Error {
    
    /// The total retry attempts were exhausted.
    case exhaustedRetryAttempts
    
    /// We got back some invalid response that can't be dealt with
    case invalidResponse
    
    /// Response parameters did not match what we expected. This should never happen. Verify that the latest SDK is being used.
    case unknownResponse
    
    /// The network request got cancelled. This could happen by nil'ing out a network request or by explicitly canceling a network request.
    case cancelled
    
    /// The network request resulted in a authentication error
    case authenticationFailure
    
    /// Could not decode image data.
    case invalidImageData
    
    /// Some generic networking error occurred
    case genericError(Error)
    
}

/// An error occurred, preventing the network controller from completing `Connection` network requests.
public enum ConnectionNetworkError: Error {
    
    /// Some generic networking error occurred
    case genericError(Error)
    
    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse
    
    init(networkControllerError: NetworkControllerError) {
        switch networkControllerError {
        case .genericError(let error):
            self = .genericError(error)
        default:
            self = .unknownResponse
        }
    }
}

