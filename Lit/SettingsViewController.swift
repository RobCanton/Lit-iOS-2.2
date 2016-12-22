//
//  SettingsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import SwiftMessages

class SettingsViewController: UITableViewController {

    
    @IBOutlet weak var addFacebookFriends: UITableViewCell!
    @IBOutlet weak var privacyPolicy: UITableViewCell!
    @IBOutlet weak var logout: UITableViewCell!
    
    
    var logoutView:LogoutView?
    var config: SwiftMessages.Config?
    var logoutWrapper = SwiftMessages()
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
        
            switch cell {
            case addFacebookFriends:
                showAddFacebookFriendsView()
                break
            case privacyPolicy:
                showPrivacyPolicy()
                break
            case logout:
                showLogoutView()
                break
            default:
                break
            }
        }
    }
    
    func showAddFacebookFriendsView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        controller.title = "Add Friends"
        controller.type = UsersListType.FacebookFriends
        self.parentViewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showPrivacyPolicy() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        controller.title = "Privacy Policy"
        self.parentViewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showLogoutView() {
        logoutView = try! SwiftMessages.viewFromNib() as? LogoutView
        logoutView!.configureDropShadow()
        
        logoutView!.logoutHandler = {
            self.logoutWrapper.hide()
            FirebaseService.logout()
        }
        
        logoutView!.cancelHandler = {
            self.logoutWrapper.hide()
        }
        
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: true)
        logoutWrapper.show(config: config!, view: logoutView!)
    }
}
