//
//  PresentedViewController.swift
//  CustomTransition
//
//  Created by naru on 2016/07/27.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit
import Whisper
import ISHPullUp

class LocationStoriesViewController: StoriesViewController {
    
    var location:Location!
    
    override func showLocation(location:Location) {
        popStoryController(true)
    }
    
    override func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else {
            cell.setForPlay()
            return
        }
        
        if cell.story.getUserId() == mainStore.state.userState.uid {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                cell.setForPlay()
            }
            actionSheet.addAction(cancelActionButton)
            
            let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
                
                if item.postPoints() > 1 {
                    let deleteController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                        cell.setForPlay()
                    }
                    deleteController.addAction(cancelAction)
                    
                    
                    
                    if item.toLocation {
                        let storyAction: UIAlertAction = UIAlertAction(title: "Remove from \(self.location.getName())", style: .Destructive)
                        { action -> Void in
                            FirebaseService.removeItemFromLocation(item, completionHandler: {
                                self.popStoryController(true)
                            })
                        }
                        deleteController.addAction(storyAction)
                    }
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
                        FirebaseService.deleteItem(item, completionHandler: {
                            self.popStoryController(true)
                        })
                    }
                    deleteController.addAction(deleteAction)
                    
                    self.presentViewController(deleteController, animated: true, completion: nil)
                } else {
                    FirebaseService.deleteItem(item, completionHandler: {
                        self.popStoryController(true)
                    })
                }
            }
            actionSheet.addAction(deleteActionButton)

            self.presentViewController(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                cell.setForPlay()
            }
            actionSheet.addAction(cancelActionButton)
            
            let OKAction = UIAlertAction(title: "Report", style: .Destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                    cell.setForPlay()
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .Destructive) { (action) in
                    FirebaseService.reportItem(item, type: ReportType.Inappropriate, showNotification: true, completionHandler: { success in
                        
                        cell.setForPlay()
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .Destructive) { (action) in
                    FirebaseService.reportItem(item, type: ReportType.Spam, showNotification: true, completionHandler: { success in
                        
                        cell.setForPlay()
                    })
                }
                alertController.addAction(OKAction2)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            actionSheet.addAction(OKAction)
            
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
}

class StoriesViewController: ISHPullUpViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    var label:UILabel!
    var tabBarRef:PopUpTabBarController!
    var userStories = [UserStory]()
    var currentIndex:NSIndexPath!
    var collectionView:UICollectionView!
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarRef.setTabBarVisible(false, animated: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appMovedToBackground), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(keyboardWasShown),
                                                         name: UIKeyboardWillChangeFrameNotification,
                                                         object: nil)
        
        UIView.animateWithDuration(0.15, animations: {
            self.statusBarShouldHide = true
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
        tabBarRef.setTabBarVisible(false, animated: false)
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.delegate = transitionController
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
            cell.optionsTappedHandler = showOptions
        }
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                }
            }
        }
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        for cell in collectionView.visibleCells() as! [StoryViewController] {
            cell.yo()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabBarRef.setTabBarVisible(true, animated: true)
        clearDirectory("temp")

        for cell in collectionView.visibleCells() as! [StoryViewController] {
            cell.cleanUp()
        }
    }

    var textField:UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.blackColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.mainScreen().bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        
        collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.registerClass(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        collectionView.opaque = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.addSubview(collectionView)
        

        label = UILabel(frame: CGRectMake(0,0,self.view.frame.width,100))
        label.textColor = UIColor.whiteColor()
        label.center = view.center
        label.textAlignment = .Center

        textField = UITextView(frame: CGRectMake(0,self.view.frame.height - 40 ,self.view.frame.width, 40))
        
        self.view.addSubview(textField)
        textField.font = UIFont(name: "AvenirNext-Medium", size: 18.0)
        textField.textColor = UIColor.whiteColor()
        textField.backgroundColor = UIColor(white: 0.0, alpha: 0.70)
        textField.hidden = true
        textField.keyboardAppearance = .Dark
        textField.returnKeyType = .Send
        textField.userInteractionEnabled = false
        textField.scrollEnabled = false
        textField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textField.text = "Send a message"
        textField.fitHeightToContent()
        textField.text = ""
        textField.delegate = self
        self.textField.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - self.textField.frame.height / 2)
    }
    
    func appMovedToBackground() {
        popStoryController(false)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.mainScreen().bounds.size
    }

    
    weak var transitionController: TransitionController!
    

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userStories.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: StoryViewController = collectionView.dequeueReusableCellWithReuseIdentifier("presented_cell", forIndexPath: indexPath) as! StoryViewController
        cell.contentView.backgroundColor = UIColor.blackColor()
        cell.story = userStories[indexPath.item]
        cell.authorOverlay.authorTappedHandler = showAuthor
        cell.authorOverlay.locationTappedHandler = showLocation
        cell.optionsTappedHandler = showOptions
        cell.storyCompleteHandler = storyComplete
        cell.viewsTappedHandler = showViewers
        return cell
    }
    
    func popStoryController(animated:Bool) {
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        navigationController?.popViewControllerAnimated(animated)
    }
    
    
    func storyComplete() {
        popStoryController(true)
    }
    
    func showAuthor(user:User) {
        self.navigationController?.delegate = self
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
        controller.uid = user.getUserId()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showLocation(location:Location) {
        self.navigationController?.delegate = self
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("LocViewController") as! LocViewController
        controller.location = location
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showViewers() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        var users = [String]()
        for (uid, _) in item.viewers {
            users.append(uid)
        }
        
        if users.count == 0 { return }
        self.navigationController?.delegate = self
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UsersListViewController") as! UsersListViewController
        
        if users.count == 1 {
            controller.title = "1 view"
        } else {
            controller.title = "\(users.count) views"
        }
        
        controller.tempIds = users
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else {
            cell.setForPlay()
            return }

        if cell.story.getUserId() == mainStore.state.userState.uid {
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                cell.setForPlay()
            }
            actionSheet.addAction(cancelActionButton)
            
            let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
                
                if item.postPoints() > 1 {
                    let deleteController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                        cell.setForPlay()
                    }
                    deleteController.addAction(cancelAction)
                    let storyAction: UIAlertAction = UIAlertAction(title: "Remove from my story", style: .Destructive)
                    { action -> Void in
                        FirebaseService.removeItemFromStory(item, completionHandler: {
                            self.popStoryController(true)
                        })
                    }
                    deleteController.addAction(storyAction)
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
                        FirebaseService.deleteItem(item, completionHandler: {
                            self.popStoryController(true)
                        })
                    }
                    deleteController.addAction(deleteAction)
                    
                    self.presentViewController(deleteController, animated: true, completion: nil)
                } else {
                    FirebaseService.deleteItem(item, completionHandler: {
                        self.popStoryController(true)
                    })
                }
            }
            actionSheet.addAction(deleteActionButton)
            
            self.presentViewController(actionSheet, animated: true, completion: nil)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                cell.setForPlay()
            }
            actionSheet.addAction(cancelActionButton)
            
            let OKAction = UIAlertAction(title: "Report", style: .Destructive) { (action) in
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                    cell.setForPlay()
                }
                alertController.addAction(cancelAction)
                
                let OKAction = UIAlertAction(title: "It's Inappropriate", style: .Destructive) { (action) in
                    FirebaseService.reportItem(item, type: ReportType.Inappropriate, showNotification: true, completionHandler: { success in
                        
                        cell.setForPlay()
                    })
                }
                alertController.addAction(OKAction)
                
                let OKAction2 = UIAlertAction(title: "It's Spam", style: .Destructive) { (action) in
                    FirebaseService.reportItem(item, type: ReportType.Spam, showNotification: true, completionHandler: { success in
                        
                        cell.setForPlay()
                    })
                }
                alertController.addAction(OKAction2)
                
                self.presentViewController(alertController, animated: true) {
                    cell.setForPlay()
                }
            }
            actionSheet.addAction(OKAction)
            
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
        
    }
    
    func getCurrentCell() -> StoryViewController? {
        if let cell = collectionView.visibleCells().first as? StoryViewController {
            return cell
        }
        return nil
    }
    
    func stopPreviousItem() {
        if let cell = getCurrentCell() {
            cell.pauseVideo()
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if keyboardUp {
            let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
            
            if translate.y > 0 {
                dismissKeyboard()
            }
            return false
        }
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        
//        if translate.y < -2 {
//            showTextfield()
//            return false
//        }
        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    
    
    func showTextfield() {
        keyboardUp = true
        textField.hidden = false
        textField.userInteractionEnabled = true
        textField.becomeFirstResponder()
        guard let cell = getCurrentCell() else { return }
        UIView.animateWithDuration(0.1, animations: {
            cell.authorOverlay.alpha = 0.0
            cell.progressBar?.alpha = 0.0
        })
    }
    
    var keyboardTap:UITapGestureRecognizer!
    var keyboardUp = false
    func keyboardWasShown(notification: NSNotification) {
        if keyboardUp {
            guard let cell = getCurrentCell() else { return }
            cell.pauseStory()
            cell.userInteractionEnabled = false
            
            let info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.textField.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - keyboardFrame.height - self.textField.frame.height / 2)
            })
        }
    }
    
    func dismissKeyboard() {
        keyboardUp = false
        textField.resignFirstResponder()
        textField.hidden = true
        textField.userInteractionEnabled = false
        guard let cell = getCurrentCell() else { return }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.textField.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - self.textField.frame.height / 2)
            cell.authorOverlay.alpha = 1.0
            cell.progressBar?.alpha = 1.0
        })
        
        cell.setForPlay()
        cell.userInteractionEnabled = true
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        
        let newItem = Int(xOffset / self.collectionView.frame.width)
        currentIndex = NSIndexPath(forItem: newItem, inSection: 0)
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! StoryViewController
        cell.cleanUp()
    }
    
    var statusBarShouldHide = false
    override func prefersStatusBarHidden() -> Bool {
        return statusBarShouldHide
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    
    func sendMessage(message:String) {
        print("Send: \(message)")
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.item else { return }
        
        let partner_uid = item.authorId
        let uid = mainStore.state.userState.uid
        
        if let conversation = checkForExistingConversation(partner_uid) {
            SocialService.sendMessage(conversation, message: message, uploadKey: item.getDownloadUrl().absoluteString, completionHandler: { success in
                if success {
                    var murmur = Murmur(title: "Message sent.")
                    murmur.backgroundColor = accentColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(3.0))
                } else {
                    var murmur = Murmur(title: "Message failed to send.")
                    murmur.backgroundColor = errorColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(3.0))
                }
            })
        } else {
            print("No existing conversation")
        }
    }
    
}

extension UIView
{
    func copyView() -> AnyObject
    {
        return NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(self))!
    }
}


extension StoriesViewController: View2ViewTransitionPresented {
    
    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
        let cell: StoryViewController = self.collectionView.cellForItemAtIndexPath(indexPath) as! StoryViewController
        
        cell.prepareForTransition(isPresenting)

        return view

    }
    
    func prepareDestinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            
            let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
            currentIndex = indexPath
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    
    
    
}

extension StoriesViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        let oldHeight = textView.frame.size.height
        textView.fitHeightToContent()
        let change = textView.frame.height - oldHeight

        textView.center = CGPoint(x: textView.center.x, y: textView.center.y - change)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            print("Length: \(textView.text.characters.count)")
            if textView.text.characters.count > 0 {
                sendMessage(textView.text)
            }
            dismissKeyboard()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}

extension UITextView {

    func fitHeightToContent() {
        let fixedWidth = self.frame.size.width
        self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = self.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        self.frame = newFrame;
    }
}
