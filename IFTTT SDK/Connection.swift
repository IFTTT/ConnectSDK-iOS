//
//  Connection.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
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
        case unknown = "unknown"
    }
    
    /// Information about a Connection's service.
    public struct Service: Equatable {
        
        /// The identifier of the service.
        public let id: String
        
        /// A name for the service.
        public let name: String
        
        /// A shorter alternative for the service's name
        public let shortName: String
        
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
    
    /// The cover image asset for the Connection
    /// As configured on platform.ifttt.com for this Connection
    public struct CoverImage {
        
        /// Describes the scaled size of this image
        /// Sizes are defined by width in pixels
        public enum Size: Int {
            /// 480 pixels wide
            case w480 = 480
            
            /// 720 pixels wide
            case w720 = 720
            
            /// 1080 pixels wide
            case w1080 = 1080
            
            /// 1440 pixels wide
            case w1440 = 1440
            
            /// 2160 pixels wide
            case w2160 = 2160
            
            /// 2880 pixels wide
            case w2880 = 2880
            
            internal static let all: [Size] = [.w2880, .w2160, .w1440, .w1080, .w720, .w480]
            
            fileprivate static func closest(to pixelWidth: CGFloat) -> Size {
                return all.first {
                    $0.rawValue < Int(pixelWidth * 1.2)
                } ?? .w480
            }
        }
        
        /// The URL for this cover image asset
        public let url: URL?
        
        /// The size of this cover image defined by its width
        public let size: Size
    }
    
    /// A value proposition for this Connection as defined on platform.iftt.com
    /// Consists of detail text and an image asset
    @available(*, deprecated, message: "Use Feature instead.")
    public struct ValueProposition {
        
        /// The text details for this value proposition
        /// Known as description on the IFTTT platform
        public let details: String
        
        /// The URl for the icon asset
        public let iconURL: URL?
    }
    
    /// A feature for this Connection as defined on platform.iftt.com
    /// Consists of title text, detail text, and an image asset
    public struct Feature {
        
        /// The title for this value proposition
        public let title: String
        
        /// The text details for this value proposition
        /// Known as description on the IFTTT platform
        public let details: String?
        
        /// The URL for the icon asset
        public let iconURL: URL?
    }
    
    /// The identifier of the `Connection`.
    public let id: String
    
    /// The name of the `Connection`.
    public let name: String
    
    /// Information about the `Connection`.
    public let description: String
    
    /// The `Status` of the `Connection`.
    public internal(set) var status: Status
    
    /// A deep link `URL` for the `Connection` on IFTTT.
    public let url: URL
    
    /// The CoverImage assets for the Connection arranged by size
    internal let coverImages: [CoverImage.Size : CoverImage]
    
    /// Returns the CoverImage for a given size or nil if it doesn't exist.
    /// This returns nil if there is not an exact match.
    /// Use `coverImage(for estimatedLayoutWidth: CGFloat, scale: CGFloat)`
    /// to return the best matching image available.
    ///
    /// - Parameter size: The size of desired image
    /// - Returns: The CoverImage asset
    public func coverImage(size: CoverImage.Size) -> CoverImage? {
        return coverImages[size]
    }
    
    /// Returns the best available CoverImage asset for a specific layout
    /// A best fit image may be up to 20% larger than the estimated layout width
    ///
    /// - Parameters:
    ///   - estimatedLayoutWidth: The estimated width of the container in which the asset will go
    ///   - scale: The current screen scale. Default value is `UIScreen.main.scale`
    /// - Returns: The CoverImage asset
    public func coverImage(for estimatedLayoutWidth: CGFloat,
                           scale: CGFloat = UIScreen.main.scale) -> CoverImage? {
        return coverImages[.closest(to: estimatedLayoutWidth * scale)]
    }
    
    // An array of `ValueProposition` for this Connection as defined on platform.ifttt.com
    @available(*, deprecated, message: "Use features property of Connection instead.")
    public var valuePropositions: [ValueProposition] {
        return valuePropositionsParser.compactMap {
            guard
                let details = $0["description"].string,
                let iconURL = $0["icon_url"].url else {
                    return nil
            }
            return Connection.ValueProposition(details: details, iconURL: iconURL)
        }
    }
    internal let valuePropositionsParser: Parser
    
    /// An array of `Feature` for this Connection as defined on platform.ifttt.com
    public let features: [Feature]
    
    /// An array of `Service`s associated with the `Connection`.
    public let services: [Service]
    
    /// The main `Service` for the `Connection`.
    public let primaryService: Service
    
    /// An array of the `Service`s that work with this `Connection`.
    public var worksWithServices: [Service] {
        return services.filter({ $0.isPrimary == false })
    }
    
    /// The service that is being connected to the primary (owner) service
    /// This defines the service icon & brand color of the button in its initial and final (activated) states
    /// It is always the first service connected
    public var connectingService: Service {
        return worksWithServices.first ?? primaryService
    }
    
    // MARK:- Native Services
    /// The set of active native service triggers for this Connection.
    let activeTriggers: Set<Trigger>
    let activePermissions: Set<NativePermission>

    public static func ==(lhs: Connection, rhs: Connection) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Connection: AnalyticsTrackable {
    var type: String {
        return "connection"
    }
    
    var identifier: String? {
        return id
    }
    
    var attributes: AnalyticsData? {
        return ["object_status": status.rawValue]
    }
}
