//
//  About.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    let primaryService: Applet.Service
    let secondaryService: Applet.Service?
    
    init(primaryService: Applet.Service, secondaryService: Applet.Service?) {
        self.primaryService = primaryService
        self.secondaryService = secondaryService
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var logoView: LogoView = {
        let secondary: UIColor = {
            if let color = secondaryService?.brandColor {
                return color
            } else if primaryService.id == "ifttt" {
                return .iftttOrange
            } else {
                return primaryService.brandColor.contrasting()
            }
        }()
        return LogoView(primary: primaryService.brandColor, secondary: secondary)
    }()
    
    lazy var wordmarkView = UILabel("IFTTT",
                                    style: Typestyle.h1.adjusting(weight: .heavy),
                                    color: .white)
    
    lazy var iftttView = UIStackView([logoView, wordmarkView],
                                     spacing: 5,
                                     axis: .vertical,
                                     alignment: .center)
    
    lazy var titleLabel = UILabel("about.title".localized,
                                  style: .h3,
                                  color: .white,
                                  alignment: .center)
    
    lazy var headerView = UIStackView([iftttView, titleLabel],
                                      spacing: 20,
                                      axis: .vertical,
                                      alignment: .center)
    
    class ItemView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
            
            let iconView = UIImageView(image: icon)
            let label = UILabel(text, style: .body,
                                color: .white,
                                alignment: .left)
            
            let stackView = UIStackView([iconView, label],
                                        spacing: 24,
                                        axis: .horizontal,
                                        alignment: .center)
            
            addSubview(stackView)
            stackView.constrain.edges(to: self)
            
            iconView.setContentHuggingPriority(.required, for: .horizontal)
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
    
    lazy var itemsStackView = UIStackView(itemViews,
                                          spacing: 10,
                                          axis: .vertical,
                                          alignment: .fill)
    
    lazy var moreButton: PillButton = {
        let ifttt = NSAttributedString(string: "IFTTT",
                                       attributes: [.font : Typestyle.h5.adjusting(weight: .heavy).callout().font,
                                                    .foregroundColor: UIColor.black])
        let text = NSMutableAttributedString(string: "about.more.button".localized,
                                             attributes: [.font: Typestyle.h5.callout().font,
                                                          .foregroundColor: UIColor.black])
        text.append(ifttt)
        return PillButton(attributedText: text, backgroundColor: .white)
    }()
    
    lazy var primaryView = UIStackView([headerView, itemsStackView, moreButton],
                                       spacing: 30,
                                       axis: .vertical,
                                       alignment: .fill)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .black
        
        let scrollView = UIScrollView()
        scrollView.addSubview(primaryView)
        
        primaryView.constrain.edges(to: scrollView)
        primaryView.constrain.width(to: scrollView)
        
        view.addSubview(scrollView)
        scrollView.constrain.edges(to: view)
        
        logoView.constrain.square(length: 42)
    }
}
