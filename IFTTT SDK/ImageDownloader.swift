//
//  ImageDownloader.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import UIKit

struct ImageDownloader {
    
    let urlSession: URLSession
    
    let cache: ImageCache
    
    init(urlSession: URLSession = URLSession(configuration: .default), cache: ImageCache = ImageCache()) {
        self.urlSession = urlSession
        self.cache = cache
    }
    
    @discardableResult
    func downloadImage(url: URL, _ completion: @escaping (Result<UIImage, NetworkControllerError>) -> Void) -> URLSessionDataTask? {
        if let image = cache.image(for: url) {
            completion(.success(image))
            return nil
        }
        let task = urlSession.dataTask(with: url) { (imageData, response, error) in
            if let imageData = imageData, let response = response, let image = UIImage(data: imageData) {
                self.cache.store(imageData: imageData, response: response, for: url)
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            } else {
                DispatchQueue.main.async {
                    if let networkError = error {
                        completion(.failure(.genericError(networkError)))
                    } else {
                        completion(.failure(.invalidImageData))
                    }
                }
            }
        }
        task.resume()
        return task
    }
}
