//
//  ImageDownloader.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

struct ImageDownloader {
    
    static let `default` = ImageDownloader()
    
    let urlSession: URLSession
    
    let cache: ImageCache
    
    init(urlSession: URLSession = URLSession(configuration: .default), cache: ImageCache = .default) {
        self.urlSession = urlSession
        self.cache = cache
    }
    
    func downloadImage(url: URL, _ completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let image = cache.image(for: url) {
            completion(image)
            return nil
        }
        let task = urlSession.dataTask(with: url) { (imageData, response, _) in
            if let imageData = imageData, let response = response, let image = UIImage(data: imageData) {
                self.cache.store(imageData: imageData, response: response, for: url)
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        task.resume()
        return task
    }
}
