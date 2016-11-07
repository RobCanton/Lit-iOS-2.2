//
//  UsersListViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

enum UsersListType {
    case Friends, Likes, Visitors, None
}

class UsersListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var statusBarBG:UIView!
    var showStatusBar = false
    
    var type = UsersListType.None
    
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
    
    var tableView:UITableView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        
        tableView = UITableView(frame:  CGRectMake(0, 0, view.frame.width, view.frame.height))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = UIColor.clearColor()

        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        tableView.reloadData()
        view.backgroundColor = UIColor.clearColor()
        
        statusBarBG = UIView(frame: CGRectMake(0,0,view.frame.width, navHeight))
        statusBarBG.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG)
        
        tableView.backgroundColor = UIColor.blackColor()
        view.backgroundColor = UIColor.blackColor()
        
        switch type {
        case .Visitors:
            userIds = location!.getVisitors()
            break
        case .Friends:
            getUserFriends()
            break
        case .Likes:
            getLikers()
            break
        default:
            
            break
        }
    }
    
    func getUserFriends() {
        
        let ref = FirebaseService.ref.child("users/social/friends/\(uid!)")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
                self.userIds = _users
            }
        })
    }
    
    func getLikers() {
        let ref = FirebaseService.ref.child("uploads/\(postKey!)/likes")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
                self.userIds = _users
            }
        })
    }
    
    func setTypeToGuests(location:Location) {
        self.location = location
        self.type = .Visitors
    }
    
    func setTypeToFriends(uid:String) {
        self.uid = uid
        self.type = .Friends
    }
    
    func setTypeToLikes(postKey:String) {
        self.postKey = postKey
        self.type = .Likes
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell
        cell.user = users[indexPath.item]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell

        let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
        controller.user = users[indexPath.item]
        self.navigationController?.pushViewController(controller, animated: true)
         tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    

    


}
