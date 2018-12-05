//
//  LocalizedStrings.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 12/4/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension String {
    func localized(arguments: CVarArg) -> String {
        return String(format: self.localized, arguments)
    }
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.sdk, value: "", comment: "")
    }
}
