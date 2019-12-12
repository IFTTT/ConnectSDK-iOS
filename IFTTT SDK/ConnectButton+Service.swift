//
//  ConnectButton+Service.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

extension ConnectButton {
    
    /// Wraps various information for configuring the connect button based on the service it is connecting.
    struct Service {
        
        /// An optional icon url to use on the button.
        let iconURL: URL?
        
        /// The color associated with the service.
        let brandColor: UIColor
    }
}
