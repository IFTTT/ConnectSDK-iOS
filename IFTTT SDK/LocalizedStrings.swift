//
//  LocalizedStrings.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension String {
    func localized(with arguments: CVarArg ...) -> String {
        return String(format: localized, locale: nil, arguments: arguments)
    }
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.sdk, value: "", comment: "")
    }
}
