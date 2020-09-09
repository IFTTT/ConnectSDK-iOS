//
//  Bundle+Helpers.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

extension Bundle {
    private static let ResourceName = "IFTTTConnectSDK"
    private static let LocalizedStringResourceName = "IFTTTConnectSDK-Localizations"
    private static let BundleExtensionName = "bundle"
    
    /**
     Defines the bundle for the SDK. The bundle for the app could be different from the bundle for the SDK which means that we might need to use the SDK bundle to get assets and other information.
     */
    static var sdk: Bundle {
        let connectButtonBundle = Bundle(for: ConnectButton.self)
        guard let urlForBundle = connectButtonBundle.url(forResource: ResourceName, withExtension: BundleExtensionName),
            let bundle = Bundle(url: urlForBundle) else {
                // If we're unable to generate the bundle indicated by `ResourceName`, fall back to returning the bundle for the `ConnectButton` instead.
                return connectButtonBundle
        }
        
        return bundle
    }
    
    /**
    Defines the bundle for the localized strings for the SDK. The bundle for the app could be different from the bundle for the SDK which means that we might need to use the localized string bundle to get assets and other information.
    */
    static var localizedStrings: Bundle {
        let connectButtonBundle = Bundle(for: ConnectButton.self)
        guard let urlForBundle = connectButtonBundle.url(forResource: LocalizedStringResourceName, withExtension: BundleExtensionName),
            let bundle = Bundle(url: urlForBundle) else {
                // If we're unable to generate the bundle indicated by `ResourceName`, fall back to returning the bundle for the `ConnectButton` instead.
                return connectButtonBundle
        }
        
        return bundle
    }
    
    /// Determines whether or not background location is enabled as a capability in the app's info dictionary.
    var backgroundLocationEnabled: Bool {
        guard let backgroundModes = infoDictionary?["UIBackgroundModes"] as? [String] else { return false }
        return backgroundModes.contains("location")
    }
    
    /// Determines whether or not background fetch is enabled as a capability in the app's info dictionary.
    var backgroundFetchEnabled: Bool {
        guard let backgroundModes = infoDictionary?["UIBackgroundModes"] as? [String] else { return false }
        return backgroundModes.contains("fetch")
    }
    
    /// Determines whether or not background processing is enabled as a capability in the app's info dictionary.
    var backgroundProcessingEnabled: Bool {
        guard let backgroundModes = infoDictionary?["UIBackgroundModes"] as? [String] else { return false }
        return backgroundModes.contains("processing")
    }
    
    /// Determines whether or not the target's info plist contains the IFTTT background processing task identifier
    var containsIFTTTBackgroundProcessingIdentifier: Bool {
        guard let backgroundTaskIdentifiers = infoDictionary?["BGTaskSchedulerPermittedIdentifiers"] as? [String] else { return false}
        
        return backgroundTaskIdentifiers.contains(SynchronizationScheduler.BackgroundProcessIdentifier)
    }
    
    var appName: String? {
        return object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

