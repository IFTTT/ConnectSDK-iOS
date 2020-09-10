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
        // Use the ConnectButtonController's locale to change the string that's returned
        let locale = ConnectButtonController.locale
        let bundle = Bundle.localizedStrings
        let localeIdentifier = locale.identifier
        
        // String files are suffixed with the locale identifier. Try to grab the strings file and check to see if it exists.
        let table = "Localizable_\(localeIdentifier)"
        
        if let tablePath = bundle.path(forResource: table, ofType: "strings"),
            FileManager.default.fileExists(atPath: tablePath) {
            return NSLocalizedString(self,
                                     tableName: table,
                                     bundle: bundle,
                                     value: "",
                                     comment: "")
        }
        else if let languageCode = locale.languageCode,
            let languageTableFallbackPath = bundle.path(forResource: "Localizable_\(languageCode)", ofType: "strings"),
            FileManager.default.fileExists(atPath: languageTableFallbackPath) {
            debugPrint("The key \(self) wasn't found in a strings file with name \(table) in the the bundle. Will try to fallback to Localizable_\(languageCode).strings file. Try reinstalling the SDK and then perform a clean/rebuild")
            return NSLocalizedString(self, tableName: "Localizable_\(languageCode)", bundle: bundle, value: "", comment: "")
        } else {
            debugPrint("The key \(self) wasn't found in a strings file with name \(table) in the the bundle. Will try to fallback to Localizable.strings file. Try reinstalling the SDK and then perform a clean/rebuild")
            return NSLocalizedString(self, bundle: bundle, value: "", comment: "")
        }
    }
}
