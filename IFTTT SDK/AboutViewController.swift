//
//  AboutViewController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices

@available(iOS 10.0, *)
class AboutViewController: UIViewController {
    
    let primaryService: Connection.Service
    let secondaryService: Connection.Service?
    
    init(primaryService: Connection.Service, secondaryService: Connection.Service?) {
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
    
    private struct Constants {
        struct Color {
            /// (IFTTT Orange) The secondary color to use when the primary service is IFTTT
            static let iftttSecondaryBrand = UIColor(hex: 0xEE4433)
            
            static let learnMoreButton = UIColor(hex: 0x222222)
        }
        
        struct Layout {
            static let logoSize: CGFloat = 42
            
            /// The margins around all the page content
            static let pageMargins = UIEdgeInsets(top: 40, left: 30, bottom: 40, right: 30)
            
            /// The spacing between the header, body, and foot
            static let pageComponentSpacing: CGFloat = 52
            
            /// The spacing between views in the header
            static let headerSpacing: CGFloat = 32
            
            /// The spacing between items in the page body
            static let bodyItemSpacing: CGFloat = 24
            
            /// The size of item icons in the page body
            static let bodyItemIconSise: CGFloat = 24
            
            /// The spacing between the icon and title in body items
            static let bodyItemIconTitleSpacing: CGFloat = 24
        }
        
        struct Text {
            /// The about page title
            static let titleText: NSAttributedString = {
                let text = NSMutableAttributedString(string: "about.title".localized, attributes: [.font : Typestyle.h3.font])
                let ifttt = NSAttributedString(string: "IFTTT", attributes: [.font : Typestyle.h3.adjusting(weight: .heavy).font])
                text.append(ifttt)
                return text
            }()
            
            /// The text for legal terms
            static let legalTermsText = LegalTermsText.string(withPrefix: "about.legal.prefix".localized,
                                                              attributes: [.foregroundColor : UIColor.white, .font : Typestyle.body.font])
        }
    }
    
    
    // MARK: - Header

    /// Dismisses the about page
    private lazy var closeButton = PillButton(Assets.About.close) {
        $0.imageView.tintColor = .white
        $0.onSelect { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        $0.backgroundColor = .clear
    }
    
    /// Aligns the close button to the top right
    private lazy var closeButtonContainer = UIStackView([closeButton]) {
        $0.axis = .vertical
        $0.alignment = .trailing
    }

    /// IFTTT color block logo, themed with the partner's colors
    private lazy var logoView: LogoView = {
        let secondary: UIColor = {
            if let color = secondaryService?.brandColor {
                return color
            } else if primaryService.id == "ifttt" {
                return Constants.Color.iftttSecondaryBrand
            } else {
                return primaryService.brandColor.contrasting()
            }
        }()
        return LogoView(primary: primaryService.brandColor, secondary: secondary)
    }()
    
    /// Centers the logoView
    private lazy var logoContainerView = UIStackView([logoView]) {
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    /// The page title
    private lazy var titleLabel = UILabel(Constants.Text.titleText) {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    /// Contains all the header components
    private lazy var headerView = UIStackView([closeButtonContainer, logoContainerView, titleLabel]) {
        $0.spacing = Constants.Layout.headerSpacing
        $0.axis = .vertical
    }
    
    
    // MARK: - Page body
    
    private class ItemView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
            
            let iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.constrain.square(length: Constants.Layout.bodyItemIconSise)
            
            let label = UILabel(text) {
                $0.font = .ifttt(Typestyle.body.adjusting(weight: .demiBold))
                $0.textColor = .white
                $0.textAlignment = .left
                $0.numberOfLines = 0
            }
            
            let stackView = UIStackView([iconView, label]) {
                $0.spacing = Constants.Layout.bodyItemIconTitleSpacing
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
        $0.spacing = Constants.Layout.bodyItemSpacing
        $0.axis = .vertical
        $0.alignment = .fill
    }
    
    
    // MARK: - Links
    
    private lazy var legalTermsView = LegalTermsView(text: Constants.Text.legalTermsText) { [weak self] url in
        self?.open(url: url)
    }
    
    private lazy var moreButton = PillButton("about.more.button".localized) {
        $0.backgroundColor = Constants.Color.learnMoreButton
        $0.label.numberOfLines = 0
        $0.label.font = .ifttt(Typestyle.h5.callout())
        $0.label.textColor = .white
        $0.onSelect { [weak self] in
            // FIXME: Typically this would point to the about page but it is not ready yet
            self?.open(url: Links.home)
        }
    }
    
    private lazy var moreButtonContainer = UIStackView([legalTermsView, moreButton]) {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 10
    }
    
    private func open(url: URL) {
        let controller = SFSafariViewController(url: url)
        present(controller, animated: true, completion: nil)
    }
    
    
    // MARK: - Page structure
    
    /// Aligns all page components
    private lazy var primaryView = UIStackView([headerView, itemsStackView, moreButtonContainer]) {
        $0.spacing = Constants.Layout.pageComponentSpacing
        $0.axis = .vertical
        $0.alignment = .fill
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = Constants.Layout.pageMargins
    }
    
    
    // MARK: - UIViewController
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .black
        
        let scrollView = UIScrollView()
        scrollView.addSubview(primaryView)
        
        primaryView.constrain.edges(to: scrollView)
        primaryView.constrain.width(to: scrollView)
        
        view.addSubview(scrollView)
        scrollView.constrain.edges(to: view)
        
        logoView.constrain.square(length: Constants.Layout.logoSize)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


// MARK: - Legal terms view

@available(iOS 10.0, *)
private extension AboutViewController {
    class LegalTermsView: UIView, UITextViewDelegate {
        
        /// One of the links was selected
        let onLinkSelected: ((URL) -> Void)?
        
        init(text: NSAttributedString, onLinkSelected: ((URL) -> Void)?) {
            self.onLinkSelected = onLinkSelected
            
            super.init(frame: .zero)
            
            let view = UITextView(frame: .zero)
            addSubview(view)
            view.constrain.edges(to: self)
            
            view.attributedText = text
            view.textAlignment = .center
            view.tintColor = .white
            view.isScrollEnabled = false
            view.isEditable = false
            view.backgroundColor = .clear
            
            view.delegate = self
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            onLinkSelected?(URL)
            return true
        }
    }
}
