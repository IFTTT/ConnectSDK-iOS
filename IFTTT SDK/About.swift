//
//  About.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

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
    
    private lazy var closeButton = PillButton(Assets.About.close) {
        $0.imageView.tintColor = .white
        $0.onSelect { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        $0.backgroundColor = .clear
    }
    
    private lazy var closeButtonContainer = UIStackView([closeButton]) {
        $0.axis = .vertical
        $0.alignment = .trailing
    }
    
    private lazy var logoView: LogoView = {
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
    
    private lazy var logoContainerView = UIStackView([logoView]) {
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    private let titleText: NSAttributedString = {
        let text = NSMutableAttributedString(string: "about.title".localized, attributes: [.font : Typestyle.h3.font])
        let ifttt = NSAttributedString(string: "IFTTT", attributes: [.font : Typestyle.h3.adjusting(weight: .heavy).font])
        text.append(ifttt)
        return text
    }()
    
    private lazy var titleLabel = UILabel(titleText) {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    private lazy var headerView = UIStackView([closeButtonContainer, logoContainerView, titleLabel]) {
        $0.spacing = 32
        $0.axis = .vertical
    }
    
    private class ItemView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
            
            let iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.constrain.square(length: 24)
            
            let label = UILabel(text) {
                $0.font = .ifttt(Typestyle.body.adjusting(weight: .demiBold))
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
    
    private lazy var itemViews: [ItemView] = [
        ItemView(icon: Assets.About.connect, text: "about.connect".localized),
        ItemView(icon: Assets.About.control, text: "about.control".localized),
        ItemView(icon: Assets.About.security, text: "about.security".localized)
    ]
    
    private lazy var itemsStackView = UIStackView(itemViews) {
        $0.spacing = 24
        $0.axis = .vertical
        $0.alignment = .fill
    }
    
    private lazy var moreButton: PillButton = {
        let button = PillButton("about.more.button".localized) {
            $0.backgroundColor = .iftttBlack
            $0.label.numberOfLines = 0
            $0.label.font = .ifttt(Typestyle.h5.callout())
            $0.label.textColor = .white
        }
        button.onSelect { [weak self] in
            let controller = SFSafariViewController(url: URL(string: "https://ifttt.com/about")!)
            self?.present(controller, animated: true, completion: nil)
        }
        return button
    }()
    
    private lazy var moreButtonContainer = UIStackView([moreButton]) {
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    private lazy var primaryView = UIStackView([headerView, itemsStackView, moreButtonContainer]) {
        $0.spacing = 52
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
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
