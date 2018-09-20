//
//  AboutIFTTT.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

class AboutIFTTTViewController: UIViewController {
    
    lazy var iconView = UIImageView(image: nil)
    
    lazy var wordmarkView = UILabel("IFTTT",
                                    style: .wordmark(size: 30),
                                    color: .white)
    
    lazy var iftttView: UIStackView = .vertical([iconView, wordmarkView],
                                                spacing: 5,
                                                alignment: .center)
    
    lazy var titleLabel = UILabel(.localized("about.title"),
                                  style: .headline,
                                  color: .white)
    
    lazy var headerView: UIStackView = .vertical([iftttView, titleLabel],
                                                 spacing: 20,
                                                 alignment: .center)
    
    class ItemView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    lazy var itemViews: [ItemView] = [
        ItemView(icon: UIImage(), text: .localized("about.control_information")),
        ItemView(icon: UIImage(), text: .localized("about.toggle_access")),
        ItemView(icon: UIImage(), text: .localized("about.security")),
        ItemView(icon: UIImage(), text: .localized("about.unlock_products"))
    ]
    
    lazy var itemsStackView: UIStackView = .vertical(itemViews,
                                                     spacing: 10,
                                                     alignment: .fill)
    
    lazy var moreButton = PillButton(text: .localized("about.more.button"),
                                     tintColor: .iftttBlack,
                                     backgroundColor: .white)
    
    lazy var primaryView: UIStackView = .vertical([headerView, itemsStackView, moreButton],
                                                  spacing: 30,
                                                  alignment: .fill)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .iftttBlack
        
        let scrollView = UIScrollView()
        scrollView.addSubview(primaryView)
        
        primaryView.constrain.edges(to: scrollView.readableContentGuide)
        primaryView.constrain.width(to: scrollView)
        
        view.addSubview(scrollView)
        scrollView.constrain.edges(to: view)
    }
}
