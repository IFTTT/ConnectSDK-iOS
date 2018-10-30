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
            ("DZFhNWa4", "Flash when Gmail arrives"),
            ("PMEHLDAV", "Turn on your LIFX lights"),
            ("mZRHhST7", "Copy a saved track to a playlist")
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let applet = applets[indexPath.row]
        let controller = AppletViewController(appletId: applet.appletId)
        navigationController?.pushViewController(controller, animated: true)
    }
}
