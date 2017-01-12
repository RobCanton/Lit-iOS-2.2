//
//  ActivityViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import Firebase

class ActivityViewController: UITableViewController, UISearchBarDelegate {
    
    
    var myStory:UserStory?
    var myStoryKeys = [String]()
    var userStories = [UserStory]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    
    var returningCell:UserStoryTableViewCell?
    
    var myStoryRef:FIRDatabaseReference?
    var responseRef:FIRDatabaseReference?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        requestActivity()
        listenToMyStory()
        listenToActivityResponse()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        myStoryRef?.removeAllObservers()
        responseRef?.removeAllObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tabBar = self.tabBarController as? PopUpTabBarController {
            tabBar.setTabBarVisible(true, animated: true)
        }
        
        if let nav = navigationController as? MasterNavigationController {
            nav.delegate = nav
        }
        
        if returningCell != nil {
            returningCell!.activate(true)
            returningCell = nil
        }
    }
    
    @IBAction func showUserSearch(sender: AnyObject) {
        
        let controller = UIStoryboard(name: "UserSearchViewController", bundle: nil)
            .instantiateViewControllerWithIdentifier("UserSearchViewController")
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    func listenToMyStory() {
        let uid = mainStore.state.userState.uid
        myStoryRef = FirebaseService.ref.child("users/activity/\(uid)")
        myStoryRef?.removeAllObservers()
        myStoryRef?.observeEventType(.Value, withBlock: { snapshot in
            var itemKeys = [String]()
            for upload in snapshot.children {
                itemKeys.append(upload.key)
            }

            if self.myStoryKeys == itemKeys {
                print("MyStory unchanged.")
            } else {
                print("MyStory changed.")
                self.myStoryKeys = itemKeys
                let myStory = UserStory(user_id: uid, postKeys: self.myStoryKeys)
                self.myStory = myStory
                self.tableView.reloadData()
            }
        })
    }

    
    func requestActivity() {
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("api/requests/activity/\(uid)")
        ref.setValue(true)
    }
    
    func listenToActivityResponse() {
        let uid = mainStore.state.userState.uid
        responseRef = FirebaseService.ref.child("api/responses/activity/\(uid)")
        responseRef?.removeAllObservers()
        responseRef?.observeEventType(.Value, withBlock: { snapshot in
            print("ACTIVITY RECIEVED: \(snapshot.value!)")
            var tempDictionary = [String:[String]]()
            for story in snapshot.children {
                let s = story as! FIRDataSnapshot
                var storyItemKeys = [String]()
                for itemKey in s.children {
                    storyItemKeys.append(itemKey.key)
                }
                tempDictionary[s.key] = storyItemKeys
            }
            self.crossCheckStories(tempDictionary)

        })
    }
    
    func crossCheckStories(tempDictionary:[String:[String]]) {
        if NSDictionary(dictionary: storiesDictionary).isEqualToDictionary(tempDictionary) {
            print("Stories unchanged. No download required")
            print("Current: \(storiesDictionary) | Temp: \(tempDictionary)")
        } else {
            print("Stories updated. Download initiated")
            storiesDictionary = tempDictionary
            var stories = [UserStory]()
            for (uid, itemKeys) in storiesDictionary {
                let story = UserStory(user_id: uid, postKeys: itemKeys)
                stories.append(story)
            }
            
            self.userStories = stories
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "UserStoryCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = true
        tableView.pagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView!.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView

        if section == 1 && userStories.count > 0 {
            headerView.hidden = false
            headerView.label.text = "FOLLOWING"
        }
        
        return headerView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && userStories.count > 0 {
            return 34
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        default:
            return 76
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if myStory != nil {
                return 1
            } else { return 0 }
        case 1:
            return userStories.count
        default:
            return 0
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
            cell.setUserStory(myStory!)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
            cell.setUserStory(userStories[indexPath.item])
            return cell
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath!
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == 0 {
            if let story = myStory {
                if story.state == .ContentLoaded {
                    presentStory(indexPath)
                } else {
                    story.downloadStory()
                }
            }
        } else if indexPath.section == 1 {
            let story = userStories[indexPath.item]
            if story.state == .ContentLoaded {
                presentStory(indexPath)
            } else {
                story.downloadStory()
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func presentStory(indexPath:NSIndexPath) {
        self.selectedIndexPath = indexPath
        
        let presentedViewController: PresentedViewController = PresentedViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
        if indexPath.section == 0 {
            presentedViewController.userStories = [myStory!]
        } else {
            presentedViewController.userStories = userStories
        }
        presentedViewController.transitionController = self.transitionController
        let i = NSIndexPath(forItem: indexPath.row, inSection: 0)
        self.transitionController.userInfo = ["destinationIndexPath": i, "initialIndexPath": indexPath]

        if let navigationController = self.navigationController {
            
            // Set transitionController as a navigation controller delegate and push.
            navigationController.delegate = transitionController
            transitionController.push(viewController: presentedViewController, on: self, attached: presentedViewController)
            
        }
    }
}

extension ActivityViewController: View2ViewTransitionPresenting {
    
    func initialFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        guard let indexPath: NSIndexPath = userInfo?["initialIndexPath"] as? NSIndexPath else {
            return CGRect.zero
        }
        if indexPath.section == 0 {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let margin = (cell.frame.height - image_height) / 2
            let x = cell.frame.origin.x + 20
            
            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
            
            let y = cell.frame.origin.y + 12 + navHeight
            
            let rect = CGRectMake(x,y,image_height, image_height)
            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)

        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let margin = (cell.frame.height - image_height) / 2
            let x = cell.frame.origin.x + 20
            
            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
            
            let y = cell.frame.origin.y + 12 + navHeight
            
            let rect = CGRectMake(x,y,image_height, image_height)
            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)
        }
        
    }
    
    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        if indexPath.section == 0 {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            return cell.contentImageView
        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            return cell.contentImageView
        }
    }
    
    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        let i = NSIndexPath(forRow: indexPath.item, inSection: 1)
        if !isPresenting {
            if let cell = tableView?.cellForRowAtIndexPath(i) as? UserStoryTableViewCell {
                returningCell?.activate(false)
                returningCell = cell
                returningCell!.deactivate()
            }
        }
        
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(indexPath) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
