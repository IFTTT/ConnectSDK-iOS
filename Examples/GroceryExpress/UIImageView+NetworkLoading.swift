//
//  UIImageView+NetworkLoading.swift
//  Grocery Express
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    private struct Storage {
        static var cache = NSCache<NSString, UIImage>()
        
        // Don't access this map directly! Use designated set/get methods on the map to safely access the map
        static var requestMap = [NSString: URLSessionDataTask]()
        static var requestMapLock = NSLock()
        
        // Don't access this map directly! Use designated set/get methods on the map to safely access the map
        static var handlerMap = [NSString: [((UIImage?) -> Void)]]()
        static var handlerMapLock = NSLock()
    }
    
    private static var cache: NSCache<NSString, UIImage> {
        get {
            return Storage.cache
        }
        set {
            Storage.cache = newValue
        }
    }
    
    private static func getHandlers(for url: URL) -> [((UIImage?) -> Void)] {
        Storage.handlerMapLock.lock(); defer { Storage.handlerMapLock.unlock() }
        return Storage.handlerMap[url.absoluteString as NSString] ?? []
    }
    
    private static func setHandler(_ handler: @escaping (UIImage?) -> Void, for url: URL) {
        Storage.handlerMapLock.lock(); defer { Storage.handlerMapLock.unlock() }
        var handlers = Storage.handlerMap[url.absoluteString as NSString]
        if handlers == nil {
            handlers = [handler]
        } else {
            handlers?.append(handler)
        }
        Storage.handlerMap[url.absoluteString as NSString] = handlers
    }
    
    private static func clearHandlers(for url: URL) {
        Storage.handlerMapLock.lock(); defer { Storage.handlerMapLock.unlock() }
        Storage.handlerMap[url.absoluteString as NSString] = nil
    }
    
    private static func getRequest(for url: URL) -> URLSessionDataTask? {
        Storage.requestMapLock.lock(); defer { Storage.requestMapLock.unlock() }
        return Storage.requestMap[url.absoluteString as NSString]
    }
    
    private static func setRequest(_ request: URLSessionDataTask, for url: URL) {
        Storage.requestMapLock.lock(); defer { Storage.requestMapLock.unlock() }
        if Storage.requestMap[url.absoluteString as NSString] != nil {
            return
        }

        Storage.requestMap[url.absoluteString as NSString] = request
    }
    
    private static func clearRequestMap(for url: URL) {
        Storage.requestMapLock.lock(); defer { Storage.requestMapLock.unlock() }
        Storage.requestMap[url.absoluteString as NSString] = nil
    }

    /// Asychronously loads the image at the parameter URL.
    ///
    /// Safe to be called on a background thread. The response image from a given url are cached so if an image exists in cache, no network request is made. Handles cases in which a network request is currently in flight and this method is called.
    /// - Parameters:
    ///     - url: The url to load the image for. If the url results in nil data, the image will be set to nil on the view.
    func setURL(_ url: URL?) {
        let imageSetClosure: (UIImage?) -> Void = { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
        
        // A nil image was passed in, set the image to nil.
        guard let url = url else {
            imageSetClosure(nil)
            return
        }
        
        UIImageView.setHandler(imageSetClosure, for: url)
        
        // There's a current network request in flight. We can just return here.
        if UIImageView.getRequest(for: url) != nil {
            return
        }
        
        imageSetClosure(nil)

        // check cached image
        if let cachedImage = UIImageView.cache.object(forKey: url.absoluteString as NSString)  {
            UIImageView.getHandlers(for: url).forEach {
                $0(cachedImage)
            }
            UIImageView.clearHandlers(for: url)
            return
        }


        // if not, download image from url
        let request = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            UIImageView.clearRequestMap(for: url)
            
            if error != nil {
                UIImageView.getHandlers(for: url).forEach {
                    $0(nil)
                }
                UIImageView.clearHandlers(for: url)
                return
            }
            
            DispatchQueue.main.async {
                guard let data = data,
                      let image = UIImage(data: data) else {
                    self.image = nil
                    return
                }
                
                UIImageView.getHandlers(for: url).forEach {
                    $0(image)
                }
                UIImageView.clearHandlers(for: url)
                UIImageView.cache.setObject(image, forKey: url.absoluteString as NSString)
            }
        })
        
        request.resume()
        UIImageView.setRequest(request, for: url)
    }
}
