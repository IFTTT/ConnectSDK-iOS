//
//  NetworkError.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/29/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

// FIXME: ConnectNetworkError

import Foundation

/// An error occurred, preventing the network controller from completing `Connection` network requests.
public enum NetworkError: Error {
    
    /// Some generic networking error occurred
    case genericError(Error)
    
    /// Response parameters did not match what we expected. This should never happen. Verify you are using the latest SDK.
    case unknownResponse
    
    /// Could not decode image data.
    case invalidImageData
}
