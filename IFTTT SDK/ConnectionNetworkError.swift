//
//  ConnectionNetworkError.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// An error occurred, preventing the network controller from completing `Connection` network requests.
public enum ConnectionNetworkError: Error {
    
    /// Some generic networking error occurred
    case genericError(Error)
    
    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse
    
    /// Could not decode image data.
    case invalidImageData
}
