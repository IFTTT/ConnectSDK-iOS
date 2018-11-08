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
        let connectionConfiguration = ConnectionConfiguration(id: applet.appletId, suggestedUserEmail: "jon@ifttt.com", activationRedirect: URL(string: "ifttt-api-example://sdk-callback")!, inviteCode: "21790-7d53f29b1eaca0bdc5bd6ad24b8f4e1c")
        let controller = AppletViewController(connectionConfiguration: connectionConfiguration)
        navigationController?.pushViewController(controller, animated: true)
    }
}
