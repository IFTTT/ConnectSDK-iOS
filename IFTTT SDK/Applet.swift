//
//  Applet.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A structure that encapsulates interacting with a connect service.
public struct Applet: Equatable {
    
    /// Represents the various states an `Applet` can be in based on interaction.
    public enum Status: String {
        
        /// This Applet has never been enabled.
        case initial = "never_enabled"
        
        /// The Applet is currently enabled.
        case enabled = "enabled"
        
        /// The Applet has been disabled.
        case disabled = "disabled"
        
        /// The Applet is in an unexpected state.
        case unknown = ""
    }
    
    /// Information about a connect service.
    public struct Service: Equatable {
        
        /// The identifier of the service.
        public let id: String
        
        /// A name for the service.
        public let name: String
        
        /// Whether the service is the primary service.
        public let isPrimary: Bool
        
        /// The `URL` to an icon that is intended to be tinted. Typically this is white or black.
        public let templateIconURL: URL
        
        /// The `URL`of an icon that is intended to be presented on top of a background with the service's `brandColor`.
        public let transparentBackgroundIconURL: URL
        
        /// A primary color defined by the service's brand.
        public let brandColor: UIColor
        
        /// The `URL` to the service.
        public let url: URL
        
        public static func ==(lhs: Service, rhs: Service) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    /// The identifier of the `Applet`.
    public let id: String
    
    /// The name of the `Applet`.
    public let name: String
    
    /// Information about the `Applet`.
    public let description: String
    
    /// The `Status` of the `Applet`.
    public internal(set) var status: Status
    
    /// The `URL` for the `Applet`.
    public let url: URL
    
    /// An array of `Service`s associated with the `Applet`.
    public let services: [Service]
    
    /// The main `Service` for the `Applet`.
    public let primaryService: Service
    
    /// An array of the `Service`s that work with this `Applet`.
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    let activationURL: URL
    
    public static func ==(lhs: Applet, rhs: Applet) -> Bool {
        return lhs.id == rhs.id
    }
}
