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
    
    var applets: [Applet] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    @objc func handleRefresh(_ sender: UIRefreshControl) {
        fetch()
    }
    
    func fetch() {
        Applet.Request.applets() { (response) in
            switch response.result {
            case .success(let applets):
                self.applets = applets
            case .failure(let error):
                let alert = UIAlertController(title: "Problem getting applets", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            if self.refreshControl?.isRefreshing == true {
                self.refreshControl?.endRefreshing()
            }
        }
        .start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self,
                                 action: #selector(handleRefresh(_:)),
                                 for: .valueChanged)
        self.refreshControl = refreshControl
        
        fetch()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "applet-detail",
            let indexPath = tableView.indexPathForSelectedRow,
            let appletController = segue.destination as? AppletViewController {
            
            appletController.applet = applets[indexPath.row]
        }
    }
}
