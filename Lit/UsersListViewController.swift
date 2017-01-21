//
//  UsersListViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import UIKit
import FBSDKCoreKit

class FacebookFriendsListViewController: UsersListViewController {
    
    var fbIds:[String]?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Facebook Friends"
        
        
        if fbIds != nil {
            let done = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(handleDone))
            self.navigationItem.rightBarButtonItem = done
            
            self.navigationItem.setHidesBackButton(true, animated: false)
            
            setFacebookFriends()
        } else {
            


            FacebookGraph.getFacebookFriends({ _userIds in
                if _userIds.count == 0 {
                    self.performSegueWithIdentifier("showLit", sender: self)
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.fbIds = _userIds
                        self.setFacebookFriends()
                    })
                }
            })
        }
    }
    
    func setFacebookFriends() {
        
        var newFriendsList = [String]()
        let following = mainStore.state.socialState.following
        for id in fbIds! {
            if !following.contains(id) {
                newFriendsList.append(id)
            }
        }
        self.userIds = newFriendsList
    }
    
    func handleDone() {
        self.performSegueWithIdentifier("showLit", sender: self)
    }
    
    
    override  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

class UsersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    
    var location:Location?
    var uid:String?
    var postKey:String?
    
    let cellIdentifier = "userCell"
    var user:User?
    var users = [User]()
    {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var userIds = [String]()
    {
        didSet{
            FirebaseService.downloadUsers(userIds, completionHandler: { users in
                self.users = users
            })
        }
    }
    
    var tempIds = [String]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        tableView.reloadData()
    }
    
    var tableView:UITableView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            
            nav.delegate = nav
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        tableView = UITableView(frame:  CGRectMake(0, 0, view.frame.width, view.frame.height))
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        tableView.backgroundColor = UIColor.clearColor()

        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        tableView.reloadData()
        view.backgroundColor = UIColor.clearColor()
        
        tableView.backgroundColor = UIColor.blackColor()
        view.backgroundColor = UIColor.blackColor()
        
        if tempIds.count > 0 {
            userIds = tempIds
        }
    }
    
    func unfollowHandler(user:User) {
        let actionSheet = UIAlertController(title: nil, message: "Unfollow \(user.getDisplayName())?", preferredStyle: .ActionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Unfollow", style: .Destructive)
        { action -> Void in
            
            SocialService.unfollowUser(user.getUserId())
        }
        actionSheet.addAction(saveActionButton)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserViewCell
        cell.setupUser(users[indexPath.item].getUserId())
        cell.unfollowHandler = unfollowHandler
        let labelX = cell.usernameLabel.frame.origin.x
        cell.separatorInset = UIEdgeInsetsMake(0, labelX, 0, 0)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserViewCell

        let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
        controller.uid = users[indexPath.row].getUserId()
        self.navigationController?.pushViewController(controller, animated: true)
         tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func addDoneButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneTapped))
        self.navigationItem.rightBarButtonItem  = doneButton
    }
    
    func doneTapped() {
        self.performSegueWithIdentifier("showLit", sender: self)
    }
    

    


}
