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

class UsersListViewController: UITableViewController {
    
    var statusBarBG:UIView!
    var showStatusBar = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.blackColor()
        tableView.dataSource = self
        tableView.delegate = self
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        tableView.reloadData()
    }
    
    func getUserFriends(uid:String) {
        
        let ref = FirebaseService.ref.child("users/social/friends/\(uid)")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
                self.userIds = _users
                self.tableView.reloadData()
            }
        })
    }
    
    func getLikers(postKey:String) {
        let ref = FirebaseService.ref.child("uploads/\(postKey)/likes")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
                self.userIds = _users
                self.tableView.reloadData()
            }
        })
    }
    
    func getLocationGuests(location:Location) {
        self.userIds = location.getVisitors()
        self.tableView.reloadData()
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 74
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell
        cell.selectionStyle = .None
        cell.user = users[indexPath.item]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell
        print("Tapped")

        let controller = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
        controller.user = users[indexPath.item]
        self.navigationController?.pushViewController(controller, animated: true)
    }
    

}
