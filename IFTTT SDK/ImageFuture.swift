//
//  ImageFuture.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/26/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation
import ObjectiveC

protocol ImageFuture: class {
    var url: URL { get }
    var isComplete: Bool { get }
    var placeholder: UIImage? { get }
    var image: UIImage? { get }
    var completion: ((UIImage?) -> Void)? { get set }
    
    func cancel()
}

extension UIImageView {
    private struct AssociationKey {
        static let activeImageFuture = "ifttt.uiimageview.imagefuture"
    }
    
    var imageFuture: ImageFuture? {
        get {
            return objc_getAssociatedObject(self, AssociationKey.activeImageFuture) as? ImageFuture
        }
        set {
            guard imageFuture?.url != newValue?.url else {
                return
            }
            imageFuture?.cancel() // Cancel any existing operation
            
            objc_setAssociatedObject(self, AssociationKey.activeImageFuture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
