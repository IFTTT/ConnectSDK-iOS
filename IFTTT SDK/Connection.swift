//
//  Connection.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 8/30/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

/// A structure representing a Connection created using the IFTTT Platform.
public struct Connection: Equatable {
    
    /// Represents the various states a `Connection` can be in based on interaction.
    public enum Status: String {
        
        /// It has never been enabled.
        case initial = "never_enabled"
        
        /// It is currently enabled.
        case enabled = "enabled"
        
        /// It has been disabled.
        case disabled = "disabled"
        
        /// It is in an unexpected state.
        case unknown = ""
    }
    
    /// Information about a Connection's service.
    public struct Service: Equatable {
        
        /// The identifier of the service.
        public let id: String
        
        /// A name for the service.
        public let name: String
        
        /// Whether the service is the primary service.
        public let isPrimary: Bool
        
        /// The `URL` to an icon that is intended to be tinted via `UIImageRenderingModeAlwaysTemplate`.
        /// Typically this is white or black. Also know as `Works with icon` on the IFTTT platform. 
        public let templateIconURL: URL
        
        /// A primary color defined by the service's brand.
        public let brandColor: UIColor
        
        /// The `URL` to the service.
        public let url: URL
        
        public static func ==(lhs: Service, rhs: Service) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    /// The identifier of the `Connection`.
    public let id: String
    
    /// The name of the `Connection`.
    public let name: String
    
    /// Information about the `Connection`.
    public let description: String
    
    /// The `Status` of the `Connection`.
    public internal(set) var status: Status
    
    /// The `URL` for the `Connection`.
    public let url: URL
    
    /// An array of `Service`s associated with the `Connection`.
    public let services: [Service]
    
    /// The main `Service` for the `Connection`.
    public let primaryService: Service
    
    /// An array of the `Service`s that work with this `Connection`.
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    public static func ==(lhs: Connection, rhs: Connection) -> Bool {
        return lhs.id == rhs.id
    }
}
