//
//  HomeViewController.swift
//  SDK Example
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

import UIKit
import IFTTT_SDK

class HomeViewController: UITableViewController {
    
    typealias Item = (appletId: String, name: String)
    
    var applets: [Item] {
        return [
            ("QbQVRU7D", "Blink your LIFX lights when your Uber is arriving"),
            ("a7deY5ri", "LIFX lights turn on when Arlo detects motion"),
            ("fSLXkRzw", "Turn on your lights at sunset"),
            ("DZFhNWa4", "Flash when Gmail arrives"),
            ("PMEHLDAV", "Turn on your LIFX lights"),
            ("mZRHhST7", "Copy a saved track to a playlist")
        ]
    }
    
    private let connectionNetworkController = ConnectionNetworkController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swapStyle = UIBarButtonItem(title: Style.currentStyle == .light ? "Use dark style": "Use light style",
                                        style: .plain,
                                        target: AppDelegate.shared!,
                                        action: #selector(AppDelegate.swapStyle))
        navigationItem.rightBarButtonItem = swapStyle
        
        tableView.backgroundColor = Style.currentStyle.backgroundColor
        tableView.separatorColor = UIColor(white: 0.5, alpha: 0.5)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    let cellId = "applet-cell"
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let applet = applets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = applet.name
        cell.backgroundColor = Style.currentStyle.backgroundColor
        cell.textLabel?.textColor = Style.currentStyle.foregroundColor
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let applet = applets[indexPath.row]
        fetchConnection(with: applet.appletId, indexPath: indexPath)
    }
    
    private func fetchConnection(with id: String, indexPath: IndexPath) {
        connectionNetworkController.start(urlRequest: Connection.Request.fetchConnection(for: id, tokenProvider: IFTTTAuthenication.shared).urlRequest) { [weak self] response in
            switch response.result {
            case .success(let applet):
                let connectionConfiguration = ConnectionConfiguration(connection: applet, suggestedUserEmail: "jon@ifttt.com", tokenProvider: IFTTTAuthenication.shared, connectAuthorizationRedirectURL: AppDelegate.connectionRedirectURL)
                let controller = AppletViewController(connectionConfiguration: connectionConfiguration)
                self?.navigationController?.pushViewController(controller, animated: true)
            case .failure:
                let alertController = UIAlertController(title: "Opps", message: "We were not able to retrieve the selected Connection. Please check your network connect.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self?.present(alertController, animated: true, completion: nil)
                self?.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
