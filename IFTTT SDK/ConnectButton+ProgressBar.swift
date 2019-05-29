//
//  ConnectButton+ProgressBar.swift
//  IFTTT SDK
//
//  Created by Michael Amundsen on 5/23/19.
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension ConnectButton {
    
    /// A `PassthroughView` subclass that represents the progress bar of the connect button.
    final class ProgressBar: PassthroughView {
        
        /// The value of how much of the progress bar has completed.
        var fractionComplete: CGFloat = 0 {
            didSet {
                update()
            }
        }
        
        private let track = UIView()
        private let bar = PassthroughView()
        
        /// Configures the progress bar background with the optionally provided `Service`.
        ///
        /// - Parameter service: An optional `Service` to set the backgrund color to.
        func configure(with service: Service?) {
            bar.backgroundColor = service?.brandColor.contrasting() ?? Color.grey
        }
        
        private func update() {
            bar.transform = CGAffineTransform(translationX: (1 - fractionComplete) * -bounds.width, y: 0)
            track.layer.cornerRadius = 0.5 * bounds.height // Progress bar should match rounded corners of connect button
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            update()
        }
        
        /// Creates a `ProgressBar`.
        init() {
            super.init(frame: .zero)
            
            // The track ensures that the progress bar stays within its intended bounds
            
            track.clipsToBounds = true
            
            addSubview(track)
            track.constrain.edges(to: layoutMarginsGuide)
            
            track.addSubview(bar)
            bar.constrain.edges(to: track)
            
            layoutMargins = .zero
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
