//
//  URLComponents+email.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 3/12/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension URLComponents {
    func fixingEmailEncoding() -> URLComponents {
        var components = self
        components.fixEmailEncoding()
        return components
    }
    
    mutating func fixEmailEncoding() {
        // We need to manually encode `+` characters in a user's e-mail because `+` is a valid character that represents a space in a url query. E-mail's with spaces are not valid.
        let updatedQuery = percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: .emailEncodingPassthrough)
        self.percentEncodedQuery = updatedQuery
    }
}

private extension CharacterSet {
    
    /// This allows '+' character to passthrough for sending an email address as a url parameter.
    static let emailEncodingPassthrough = CharacterSet(charactersIn: "+").inverted
}
