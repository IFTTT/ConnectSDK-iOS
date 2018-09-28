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
                                    style: Typestyle.h1.adjusting(weight: .heavy),
                                    color: .white)
    
    lazy var iftttView: UIStackView = .vertical([iconView, wordmarkView],
                                                spacing: 5,
                                                alignment: .center)
    
    lazy var titleLabel = UILabel("about.title".localized,
                                  style: .h3,
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
        ItemView(icon: Assets.About.connect, text: "about.connect".localized),
        ItemView(icon: Assets.About.control, text: "about.control".localized),
        ItemView(icon: Assets.About.manage, text: "about.manage".localized),
        ItemView(icon: Assets.About.security, text: "about.security".localized)
    ]
    
    lazy var itemsStackView: UIStackView = .vertical(itemViews,
                                                     spacing: 10,
                                                     alignment: .fill)
    
    lazy var moreButton: PillButton = {
        let ifttt = NSAttributedString(string: "IFTTT",
                                       attributes: [.font : Typestyle.h5.adjusting(weight: .heavy).callout(),
                                                    .foregroundColor: UIColor.iftttBlack])
        let text = NSMutableAttributedString(string: "about.more.button".localized,
                                             attributes: [.font: Typestyle.h5.callout(),
                                                          .foregroundColor: UIColor.iftttBlack])
        text.append(ifttt)
        return PillButton(attributedText: text, backgroundColor: .white)
    }()
    
    lazy var primaryView: UIStackView = .vertical([headerView, itemsStackView, moreButton],
                                                  spacing: 30,
                                                  alignment: .fill)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .iftttBlack
        
        let scrollView = UIScrollView()
        scrollView.addSubview(primaryView)
        
        primaryView.constrain.edges(to: scrollView.readableContentGuide)
        
        view.addSubview(scrollView)
        scrollView.constrain.edges(to: view)
    }
}
