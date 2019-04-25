//
//  AboutViewController.swift
//  IFTTT SDK
//
//  Created by Jon Chmura on 9/17/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit

@available(iOS 10.0, *)
class AboutViewController: UIViewController {
    
    private let primaryService: Connection.Service
    private let secondaryService: Connection.Service
    
    init(primaryService: Connection.Service, secondaryService: Connection.Service) {
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
            static let mediumGrey = UIColor(hex: 0x666666)
        }
        
        struct Layout {
            static let serviceIconSize: CGFloat = 44
            
            static let serviceIconSpacing: CGFloat = 24
            
            /// The margins around all the page content
            static let pageMargins = UIEdgeInsets(top: 20, left: 30, bottom: 40, right: 30)
            
            /// The spacing between the close button and the page header
            static let closeButtonHeaderSpacing: CGFloat = 20
            
            /// The spacing between views in the header
            static let headerSpacing: CGFloat = 16
            
            /// The spacing between the header, body, and footer
            static let bodyItemMargins: CGFloat = 36
            
            /// The spacing between items in the page body
            static let bodyItemSpacing: CGFloat = 24
            
            /// The size of item icons in the page body
            static let bodyItemIconSise: CGFloat = 24
            
            /// The spacing between the icon and title in body items
            static let bodyItemIconTitleSpacing: CGFloat = 24
            
            /// The spacing between the download in app store button and the legal terms
            static let footerSpacing: CGFloat = 24
        }
        
        struct Text {
            /// The about page title
            static func titleText(connects primaryService: Connection.Service,
                                  with secondaryService: Connection.Service) -> NSAttributedString {
                let rawText = "about.title".localized(with: primaryService.shortName,
                                                      secondaryService.shortName)
                let text = NSMutableAttributedString(string: rawText,
                                                     attributes: [.font : UIFont.h3(weight: .demiBold)])
                let ifttt = NSAttributedString(string: "IFTTT",
                                               attributes: [.font : UIFont.h3(weight: .heavy)])
                text.insert(ifttt, at: 0)
                return text
            }
            
            /// The text for legal terms
            static var legalTermsText: NSAttributedString {
                return LegalTermsText.string(withPrefix: "about.legal.prefix".localized,
                                                              attributes: [.foregroundColor : Color.mediumGrey,
                                                                           .font : UIFont.body(weight: .demiBold)])
            }
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
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 0,
                                        left: 0,
                                        bottom: Constants.Layout.closeButtonHeaderSpacing,
                                        right: 0)
    }
    
    private lazy var serviceIconsView = ServiceIconsView(primaryIcon: primaryService.templateIconURL,
                                                         secondaryIcon: secondaryService.templateIconURL)
    
    /// The page title
    private lazy var titleLabel = UILabel(Constants.Text.titleText(connects: primaryService, with: secondaryService)) {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    /// Contains all the header components
    private lazy var headerView = UIStackView([serviceIconsView, titleLabel]) {
        $0.spacing = Constants.Layout.headerSpacing
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    
    // MARK: - Page body
    
    private lazy var valuePropositionViews: [ValuePropositionView] = [
        ValuePropositionView(icon: Assets.About.connect, text: "about.connect".localized),
        ValuePropositionView(icon: Assets.About.control, text: "about.control".localized),
        ValuePropositionView(icon: Assets.About.security, text: "about.security".localized),
        ValuePropositionView(icon: Assets.About.manage, text: "about.manage".localized)
    ]
    
    private lazy var itemsStackView = UIStackView(valuePropositionViews) {
        $0.spacing = Constants.Layout.bodyItemSpacing
        $0.axis = .vertical
        $0.alignment = .fill
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: Constants.Layout.bodyItemMargins,
                                        left: 0,
                                        bottom: Constants.Layout.bodyItemMargins,
                                        right: 0)
    }
    
    
    // MARK: - Links
    
    private lazy var legalTermsView = LegalTermsView(text: Constants.Text.legalTermsText) { [weak self] url in
        self?.open(url: url)
    }
    
    private lazy var downloadOnAppStoreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Assets.About.downloadOnAppStore, for: [])
        return button
    }()
    
    private lazy var footerView = UIStackView([downloadOnAppStoreButton, legalTermsView]) {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = Constants.Layout.footerSpacing
    }
    
    private func open(url: URL) {
        let controller = SFSafariViewController(url: url)
        present(controller, animated: true, completion: nil)
    }
    
    /// Acts as the delegate for displaying the IFTTT app store page
    private class StoreProductViewControllerDelegate: NSObject, SKStoreProductViewControllerDelegate {
        public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    private var storeProductViewControllerDelegate = StoreProductViewControllerDelegate()
    
    /// Presents an App Store view for the IFTTT app
    @objc private func showAppStorePage() {
        let viewController = SKStoreProductViewController()
        let parameters: [String : Any] = [SKStoreProductParameterITunesItemIdentifier : API.iftttAppStoreId]
        viewController.loadProduct(withParameters: parameters, completionBlock: nil)
        viewController.delegate = storeProductViewControllerDelegate
        present(viewController, animated: true)
    }
    
    
    // MARK: - Page structure
    
    /// Aligns all page components
    private lazy var primaryView = UIStackView([closeButtonContainer, headerView, itemsStackView, footerView]) {
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
        
        downloadOnAppStoreButton.addTarget(self, action: #selector(showAppStorePage), for: .touchUpInside)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


// MARK: - Service icons header view

@available(iOS 10.0, *)
private extension AboutViewController {
    /// Presents the primary and secondary service icons with an arrow connecting the two
    final class ServiceIconsView: UIView {
        
        init(primaryIcon: URL, secondaryIcon: URL) {
            super.init(frame: .zero)
            
            let primaryIconView = UIImageView()
            let secondaryIconView = UIImageView()
            
            primaryIconView.constrain.square(length: Constants.Layout.serviceIconSize)
            secondaryIconView.constrain.square(length: Constants.Layout.serviceIconSize)
            
            let arrowIcon = UIImageView(image: Assets.About.connectArrow)
            
            let stackView = UIStackView([primaryIconView, arrowIcon, secondaryIconView]) { (view) in
                view.axis = .horizontal
                view.spacing = Constants.Layout.serviceIconSpacing
                view.alignment = .center
            }
            addSubview(stackView)
            stackView.constrain.edges(to: self)
            
            let serviceIconsDownloader = ServiceIconsNetworkController()
            serviceIconsDownloader.setImage(with: primaryIcon, for: primaryIconView)
            serviceIconsDownloader.setImage(with: secondaryIcon, for: secondaryIconView)
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


// MARK: - Value proposition view

@available(iOS 10.0, *)
private extension AboutViewController {
    final class ValuePropositionView: UIView {
        init(icon: UIImage, text: String) {
            super.init(frame: .zero)
            
            let iconView = UIImageView(image: icon)
            iconView.tintColor = Constants.Color.mediumGrey
            iconView.contentMode = .scaleAspectFit
            iconView.constrain.square(length: Constants.Layout.bodyItemIconSise)
            
            let label = UILabel(text) {
                $0.font = .body(weight: .demiBold)
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
}


// MARK: - Legal terms view

@available(iOS 10.0, *)
private extension AboutViewController {
    final class LegalTermsView: UIView, UITextViewDelegate {
        
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
            // This sets the color of the links
            // The should match the text
            view.tintColor = Constants.Color.mediumGrey
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
            return false
        }
    }
}
