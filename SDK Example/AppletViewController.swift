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

    let appletId: String
    
    init(appletId: String) {
        self.appletId = appletId
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
        label.textColor = .black
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    lazy var connectButton = ConnectButton()
    
    private var connectInteractor: ConnectInteraction?
    
    private func configure(with applet: Applet) {
        titleLabel.text = applet.name
        descriptionLabel.text = applet.description
        
        connectInteractor = ConnectInteraction(connectButton, applet: applet, delegate: self)
    }
    
    private func fetch() {
        Applet.Request.applet(id: appletId) { (response) in
            switch response.result {
            case .success(let applet):
                self.configure(with: applet)
            case .failure:
                break
            }
        }
        .start()
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .white
        
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
        
        fetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
}

extension AppletViewController: ConnectInteractionDelegate {
    func connectInteraction(_ controller: ConnectInteraction, show viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    func connectInteraction(_ interaction: ConnectInteraction, nonFatalActivationError error: AppletConnectionError) {
        
    }
    func connectInteraction(_ controller: ConnectInteraction, appletActivationFinished outcome: AppletConnectionOutcome) {
        
    }
    func connectInteraction(_ interation: ConnectInteraction, appletDeactivated applet: Applet) {
        
    }
    func connectInteraction(_ interation: ConnectInteraction, appletDeactivationFailedWithError error: AppletConnectionError) {
        
    }
}
