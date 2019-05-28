//
//  Result<ValueType,ErrorType>.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/6/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// An object to model success and failure states from an API.
public enum Result<ValueType, ErrorType: Error> {
    
    /// The operation was successful. The passed associated value is the result that was returned from the API.
    case success(ValueType)
    
    /// The operation failed. The passed associated value is the error that was encountered.
    case failure(ErrorType)
}

extension Result {
    
    /// The associated `ValueType` for `success`. `nil` on `failure`.
    var value: ValueType? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// The associated `ErrorType` for `failure`s. Returns nil on `success`.
    var error: ErrorType? {
        switch self {
        case .success:
            return nil
        case.failure(let error):
            return error
        }
    }
    
    /// Whether the receiver is the `.success` case.
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
