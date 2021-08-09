//
//  Result<ValueType,ErrorType>.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

extension Result {
    /// The associated value for `success`es. Returns `nil` on `failure`.
    var value: Success? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    /// The associated error for `failure`s. Returns `nil` on `success`.
    var error: Failure? {
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
