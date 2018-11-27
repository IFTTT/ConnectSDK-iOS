//
//  ImageCache.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct ImageCache {
    
    static var `default` = ImageCache()
    
    let urlCache: URLCache
    
    init(urlCache: URLCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)) {
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
