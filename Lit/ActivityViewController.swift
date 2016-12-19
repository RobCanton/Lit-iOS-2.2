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

class ActivityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var myStory:Story?
    var myStoryKeys = [String]()
    var stories = [Story]()
    var postKeys = [String]()
    
    var storiesDictionary = [String:[String]]()
    
    var myStoryRef:FIRDatabaseReference?
    var responseRef:FIRDatabaseReference?
    
    @IBOutlet weak var tableView: UITableView!
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
    
    
    func listenToMyStory() {
        let uid = mainStore.state.userState.uid
        myStoryRef = FirebaseService.ref.child("users/uploads/\(uid)")
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
                FirebaseService.downloadStory(self.myStoryKeys, completionHandler: { items in
                    let story = Story(author_uid: uid)
                    story.setItems(items)
                    self.myStory = story
                    self.tableView?.reloadData()
                    self.downloadMyStory(false)
                })
            }
        })
    }

    func downloadMyStory(force:Bool) {
        
        guard let story = myStory else { return }
        let indexPath = [NSIndexPath(forRow: 0, inSection: 0)]
        if story.needsDownload() {
            if force {
                story.downloadStory({ complete in
                    self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
                })
            }
        } else {
            story.state = .Loaded
        }
        self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
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
            downloadStoryItems()
        }
    }
    
    
    func downloadStoryItems() {
        var _stories = [Story]()
        var count = 0
        if storiesDictionary.count == 0 {
            self.stories = [Story]()
            self.tableView!.reloadData()
        }
        for (uid, itemKeys) in storiesDictionary {
            
            FirebaseService.downloadStory(itemKeys, completionHandler: { items in
                if items.count > 0 {
                    let story = Story(author_uid: uid)
                    story.setItems(items)
                    _stories.append(story)
                }
                count += 1
                if count >= self.storiesDictionary.count {
                    count = -1
                    self.stories = _stories
                    self.tableView!.reloadData()
                    self.downloadAllStories()
                }
            })
        }
    }
    
    func getStoryIndex(_story:Story) -> Int? {
        for i in 0..<stories.count {
            let story = stories[i]
            if _story.getAuthorID() == story.getAuthorID() {
                return i
            }
        }
        return nil
    }
    
    func downloadAllStories() {
        for story in self.stories {
            downloadStory(story, force: false)
        }
    }
    
    func downloadStory(story:Story, force:Bool) {
        
        guard let i = self.getStoryIndex(story)  else { return }
        let indexPath = [NSIndexPath(forRow: i, inSection: 1)]
        if story.needsDownload() {
            if force {
                story.downloadStory({ complete in
                    self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
                })
            }
        } else {
            story.state = .Loaded
        }
        self.tableView?.reloadRowsAtIndexPaths(indexPath, withRowAnimation: .Automatic)
    }
    
    func reloadStoryCells() {
        
        var indexPaths = [NSIndexPath]()
        for i in 0..<stories.count {
            indexPaths.append(NSIndexPath(forRow: i, inSection: 1))
        }
        
        self.tableView?.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 20.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        let nib = UINib(nibName: "UserStoryTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "UserStoryCell")
        let nib2 = UINib(nibName: "MyStoryTableViewCell", bundle: nil)
        tableView.registerNib(nib2, forCellReuseIdentifier: "MyStoryCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = true
        tableView.pagingEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
        tableView!.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        tableView!.reloadData()
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView

        if section == 1 && stories.count > 0 {
            headerView.hidden = false
            headerView.label.text = "Recent Updates"
        }
        
        return headerView
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && stories.count > 0 {
            return 34
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        default:
            return 80
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if myStory != nil {
                return 1
            } else { return 0 }
        case 1:
            return stories.count
        default:
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("MyStoryCell", forIndexPath: indexPath) as! MyStoryTableViewCell
            cell.setStory(myStory!)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserStoryCell", forIndexPath: indexPath) as! UserStoryTableViewCell
            cell.setStory(stories[indexPath.item])
            return cell
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    let transitionController: TransitionController = TransitionController()
    var selectedIndexPath: NSIndexPath!
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == 0 {
            if let story = myStory {
                if story.state == .Loaded {
                    print("PRESENT MY STORY")
                    presentStory(indexPath)
                } else {
                    print("DOWNLOAD MY STORY")
                    downloadMyStory(true)
                }
            }
        } else if indexPath.section == 1 {
            let story = stories[indexPath.item]
            if story.state == .Loaded {
                presentStory(indexPath)
            } else {
                downloadStory(story, force: true)
            }
        }
        

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func presentStory(indexPath:NSIndexPath) {
        self.selectedIndexPath = indexPath
        
        let presentedViewController: PresentedViewController = PresentedViewController()
        presentedViewController.tabBarRef = self.tabBarController! as! PopUpTabBarController
        if indexPath.section == 0 {
            presentedViewController.stories = [myStory!]
        } else {
            presentedViewController.stories = stories
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
            let cell: MyStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! MyStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let margin = (cell.frame.height - image_height) / 2
            let x = cell.frame.origin.x + margin
            
            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
            
            let y = cell.frame.origin.y + margin + navHeight
            
            let rect = CGRectMake(x,y,image_height, image_height)
            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)

        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            let image_frame = cell.contentImageView.frame
            let image_height = image_frame.height
            let margin = (cell.frame.height - image_height) / 2
            let x = cell.frame.origin.x + margin
            
            let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
            
            let y = cell.frame.origin.y + margin + navHeight
            
            let rect = CGRectMake(x,y,image_height, image_height)
            return self.tableView!.convertRect(rect, toView: self.tableView!.superview)
        }
        
    }
    
    func initialView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        if indexPath.section == 0 {
            let cell: MyStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! MyStoryTableViewCell
            return cell.contentImageView
        } else {
            let cell: UserStoryTableViewCell = self.tableView!.cellForRowAtIndexPath(indexPath)! as! UserStoryTableViewCell
            return cell.contentImageView
        }
    }
    
    func prepareInitialView(userInfo: [String : AnyObject]?, isPresenting: Bool) {
        
        let indexPath: NSIndexPath = userInfo!["initialIndexPath"] as! NSIndexPath
        if !isPresenting && !self.tableView!.indexPathsForVisibleRows!.contains(indexPath) {
            self.tableView!.reloadData()
            self.tableView!.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: false)
            self.tableView!.layoutIfNeeded()
        }
    }
}
