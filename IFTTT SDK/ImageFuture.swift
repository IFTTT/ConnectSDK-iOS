//
//  ImageFuture.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

protocol ImageFuture: class {
    var url: URL { get }
    var isComplete: Bool { get }
    var placeholder: UIImage? { get }
    var image: UIImage? { get }
    var completion: ((UIImage?) -> Void)? { get set }
    
    func cancel()
}

private var futuresByImageView: [UIImageView : ImageFuture] = [:]

extension UIImageView {
    var imageFuture: ImageFuture? {
        get {
            return futuresByImageView[self]
        }
        set {
            guard imageFuture?.url != newValue?.url else {
                return
            }
            imageFuture?.cancel() // Cancel any existing operation
            
            futuresByImageView[self] = newValue
            imageFuture?.update(imageView: self)
        }
    }
}

private extension ImageFuture {
    func update(imageView: UIImageView) {
        imageView.image = image ?? placeholder
        
        if isComplete {
            imageView.imageFuture = nil
        } else {
            completion = { [weak imageView] image in
                imageView?.imageFuture = nil
                imageView?.image = image
            }
        }
    }
}
