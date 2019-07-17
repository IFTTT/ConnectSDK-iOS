//
//  ServiceIconsNetworkController.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

/// Implementation of `ImageViewNetworkController` to download service icons
class ServiceIconsNetworkController: ImageViewNetworkController {
    private let downloader = ImageDownloader()
    
    /// Prefetch and cache service icon images for this `Connection`.
    /// This will be it very unlikely that an image is delayed and visually "pops in".
    func prefetchImages(for connection: Connection) {
        connection.services.forEach {
            downloader.downloadImage(url: $0.templateIconURL, { _ in})
        }
    }
    
    private var currentRequests = [UIImageView : URLSessionDataTask]()
    
    func setImage(with url: URL?, for imageView: UIImageView) {
        if let existingTask = currentRequests[imageView] {
            if existingTask.originalRequest?.url == url {
                return // This is a duplicate request
            } else {
                // The image url was changed
                existingTask.cancel()
                currentRequests[imageView] = nil
            }
        }
        
        imageView.image = nil
        if let url = url {
            let task = downloader.downloadImage(url: url) { (result) in
                switch result {
                case .success(let image):
                    imageView.image = image
                case .failure:
                    // Images that fail to load are left blank
                    // Since we attempt to precatch images, this is actually the second try
                    break
                }
            }
            currentRequests[imageView] = task
        }
    }
}
