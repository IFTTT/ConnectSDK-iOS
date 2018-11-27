//
//  ImageDownloader.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

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
