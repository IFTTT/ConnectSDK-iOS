//
//  Images.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/18/18.
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

struct ImageDownloader {
    
    static var `default` = ImageDownloader()
    
    let urlSession: URLSession
    
    let cache: ImageCache
    
    init(urlSession: URLSession = URLSession(configuration: .default), cache: ImageCache = .default) {
        self.urlSession = urlSession
        self.cache = cache
    }
    
    func get(imageURL: URL, _ completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let image = cache.image(for: imageURL) {
            completion(image)
            return nil
        }
        let task = urlSession.dataTask(with: imageURL) { (imageData, response, _) in
            DispatchQueue.main.async {
                if let imageData = imageData, let response = response, let image = UIImage(data: imageData) {
                    self.cache.store(imageData: imageData, response: response, for: imageURL)       
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
        task.resume()
        return task
    }
}

private var tasksByImageView: [UIImageView : URLSessionDataTask] = [:]

extension UIImageView {
    func set(imageURL: URL) {
        if let existingTask = tasksByImageView[self] {
            if existingTask.originalRequest?.url == imageURL {
                return // Activate request for the same image, skip
            } else {
                existingTask.cancel() // New request for a different image, cancel the old one
                tasksByImageView[self] = nil
                image = nil
            }
        }
        let task = ImageDownloader.default.get(imageURL: imageURL) { (image) in
            tasksByImageView[self] = nil
            self.image = image
        }
        tasksByImageView[self] = task
    }
    func cancelImageRequests() {
        tasksByImageView[self]?.cancel()
        tasksByImageView[self] = nil
    }
}
