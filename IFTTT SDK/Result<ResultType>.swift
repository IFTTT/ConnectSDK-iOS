//
//  ResultType.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 11/6/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// Models success and failure states from an API.
enum Result<ResultType> {
    
    /// The operation was successful. The associated value is the result that was returned from the API.
    case success(ResultType)
    
    /// The operation failed. The associated value is the error that was encountered.
    case failure(Error)
}

extension Result {
    
    /// The associated value of the result on `.success`. `nil` on `.failure`.
    var value: ResultType? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
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
