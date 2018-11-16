//
//  LogoView.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 10/1/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class LogoView: UIView {
    
    var primaryColor: UIColor {
        get { return primaryView.backgroundColor ?? .iftttBlue }
        set { primaryView.backgroundColor = newValue }
    }
    
    var secondaryColor: UIColor {
        get { return secondaryView.backgroundColor ?? .iftttOrange }
        set { secondaryView.backgroundColor = newValue }
    }
    
    private let primaryView = UIView()
    private let secondaryView = UIView()
    
    init(primary: UIColor = .iftttBlue, secondary: UIColor = .iftttOrange) {
        super.init(frame: .zero)
        
        primaryColor = primary
        secondaryColor = secondary
        
        addSubview(primaryView)
        addSubview(secondaryView)
        
        primaryView.constrain.edges(to: self)
        
        secondaryView.heightAnchor.constraint(equalTo: primaryView.heightAnchor, multiplier: 1.0 / 3.0).isActive = true
        secondaryView.constrain.edges(to: self, edges: [.left, .bottom, .right])
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
}
