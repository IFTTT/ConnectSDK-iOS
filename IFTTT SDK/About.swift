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
        
        modalTransitionStyle = .coverVertical
        modalPresentationStyle = .formSheet
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
    
    lazy var wordmarkView = UILabel("IFTTT") {
        $0.font = .ifttt(Typestyle.h1.adjusting(weight: .heavy))
        $0.textColor = .white
    }
    
    lazy var iftttView = UIStackView([logoView, wordmarkView]) {
        $0.spacing = 24
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    lazy var titleLabel = UILabel("about.title".localized) {
        $0.font = .ifttt(.h3)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    lazy var headerView = UIStackView([iftttView, titleLabel]) {
        $0.spacing = 40
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    lazy var closeButton = PillButton(Assets.About.close) {
        $0.imageView.tintColor = .white
        $0.onSelect { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        $0.backgroundColor = .clear
    }
    
    class ItemView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
            
            let iconView = UIImageView(image: icon)
            let label = UILabel(text) {
                $0.font = .ifttt(.body)
                $0.textColor = .white
                $0.textAlignment = .left
                $0.numberOfLines = 0
            }
            
            let stackView = UIStackView([iconView, label]) {
                $0.spacing = 24
                $0.axis = .horizontal
                $0.alignment = .center
            }
            
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
    
    lazy var itemsStackView = UIStackView(itemViews) {
        $0.spacing = 10
        $0.axis = .vertical
        $0.alignment = .fill
    }
    
    lazy var moreButton: PillButton = {
        let ifttt = NSAttributedString(string: "IFTTT",
                                       attributes: [.font : Typestyle.h5.adjusting(weight: .heavy).callout().font,
                                                    .foregroundColor: UIColor.black])
        let text = NSMutableAttributedString(string: "about.more.button".localized,
                                             attributes: [.font: Typestyle.h5.callout().font,
                                                          .foregroundColor: UIColor.black])
        text.append(ifttt)
        let button = PillButton(text) {
            $0.backgroundColor = .white
            $0.label.numberOfLines = 0
        }
        button.onSelect { [weak self] in
            // FIXME: Link to IFTTT About page
        }
        return button
    }()
    
    lazy var primaryView = UIStackView([headerView, itemsStackView, moreButton]) {
        $0.spacing = 32
        $0.axis = .vertical
        $0.alignment = .fill
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 40, left: 30, bottom: 40, right: 30)
    }
    
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
        
        scrollView.addSubview(closeButton)
        closeButton.centerYAnchor.constraint(equalTo: logoView.topAnchor).isActive = true
        closeButton.constrain.edges(to: scrollView, edges: [.right], inset: UIEdgeInsets(inset: 24))
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
