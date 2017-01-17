//
//  SettingsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController {

    @IBOutlet weak var addFacebookFriends: UITableViewCell!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var privacyPolicy: UITableViewCell!
    @IBOutlet weak var logout: UITableViewCell!
    
    
    var notificationsRef:FIRDatabaseReference?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        let uid = mainStore.state.userState.uid
        
        notificationsRef = FirebaseService.ref.child("users/settings/\(uid)/push_notifications")
        notificationsRef!.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                if let val = snapshot.value as? Bool {
                    if val {
                        self.notificationsSwitch.setOn(true, animated: false)
                    } else {
                        self.notificationsSwitch.setOn(false, animated: false)
                    }
                }
            } else {
                self.notificationsSwitch.setOn(true, animated: false)
            }
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
        
            switch cell {
            case addFacebookFriends:
                self.performSegueWithIdentifier("toAddFacebookFriends", sender: self)
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
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    
    @IBAction func toggleNotificationsSwitch(sender: UISwitch) {
        if sender.on {
            notificationsRef?.setValue(true)
        } else {
            notificationsRef?.setValue(false)
        }
    }

    func showPrivacyPolicy() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        controller.title = "Privacy Policy"
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showLogoutView() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Log Out", style: .Destructive)
        { action -> Void in
            FirebaseService.logout()
        }
        actionSheet.addAction(saveActionButton)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
}
