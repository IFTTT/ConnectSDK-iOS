//
//  ImageViewNetworkController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 11/29/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import Foundation

protocol ImageViewNetworkController {
    func setImage(with url: URL?, for imageView: UIImageView)
}
