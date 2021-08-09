//
//  Result<ValueType,ErrorType>.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

#if swift(<5.0)
/// An object to model success and failure states from an API.
public enum Result<ValueType, ErrorType: Error> {
    /// The operation was successful. The passed associated value is the result that was returned from the API.
    case success(ValueType)

    /// The operation failed. The passed associated value is the error that was encountered.
    case failure(ErrorType)

    /// An alias for `ValueType`.
    typealias Success = ValueType

    /// An alias for `ErrorType`.
    typealias Failure = ErrorType
}
#endif

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
