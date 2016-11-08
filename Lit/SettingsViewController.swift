//
//  SettingsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import SwiftMessages
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class SettingsViewController: UITableViewController {

    @IBOutlet weak var logout: UITableViewCell!
    var logoutView:LogoutView?
    var config: SwiftMessages.Config?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        if cell === logout {
            print("logout")
            showLogoutView()
        }
    }
    
    func showLogoutView() {
        logoutView = try! SwiftMessages.viewFromNib() as? LogoutView
        logoutView!.configureDropShadow()
        
        logoutView!.logoutHandler = {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            try! FIRAuth.auth()!.signOut()
            mainStore.dispatch(UserIsUnauthenticated())
            SwiftMessages.hide()
        }
        
        logoutView!.cancelHandler = {
            SwiftMessages.hide()
        }
        
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: true)
        SwiftMessages.show(config: config!, view: logoutView!)
    }
}
