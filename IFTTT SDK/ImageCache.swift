//
//  ImageCache.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct ImageCache {
    
    struct Capacity {
        private static let MB = 1024 * 1024 // One MegaByte
        
        static let inMemory = 4 * MB
        static let onDisk = 20 * MB
    }
    
    let urlCache: URLCache
    
    init(urlCache: URLCache = URLCache(memoryCapacity: Capacity.inMemory,
                                       diskCapacity: Capacity.onDisk,
                                       diskPath: nil)) {
        self.urlCache = urlCache
    }
    
    func store(imageData: Data, response: URLResponse, for url: URL) {
        let cachedResponse = CachedURLResponse(response: response, data: imageData)
        urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
    }
    
    func image(for url: URL) -> UIImage? {
        guard let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)) else {
            return nil
        }
        return UIImage(data: cachedResponse.data)
    }
}
