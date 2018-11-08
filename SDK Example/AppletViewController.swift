//
//  ViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

class AppletViewController: UIViewController {
    
    private let connectionConfiguration: ConnectionConfiguration
    
    init(connectionConfiguration: ConnectionConfiguration) {
        self.connectionConfiguration = connectionConfiguration
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    private lazy var connectButton = ConnectButton()
    
    private lazy var connectInteractor = ConnectInteraction(connectButton: connectButton, connectionConfiguration: connectionConfiguration, delegate: self)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Style.currentStyle.backgroundColor
        [titleLabel, descriptionLabel].forEach { $0.textColor = Style.currentStyle.foregroundColor }
        connectButton.style = Style.currentStyle == .light ? .light : .dark
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, connectButton])
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        
        let scrollView = UIScrollView(frame: .zero)
        scrollView.keyboardDismissMode = .onDrag
        scrollView.addSubview(stackView)
        
        view.addSubview(scrollView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = connectInteractor.applet.name
        descriptionLabel.text = connectInteractor.applet.description
    }
}

extension AppletViewController: ConnectInteractionDelegate {
    
    func connectInteraction(_ controller: ConnectInteraction, show viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    
    func connectInteraction(_ connectInteraction: ConnectInteraction, didFinishActivationWithResult result: Result<Applet>) {
        
    }
    
    func connectInteraction(_ connectInteraction: ConnectInteraction, didFinishDeactivationWithResult result: Result<Applet>) {
        
    }

}
