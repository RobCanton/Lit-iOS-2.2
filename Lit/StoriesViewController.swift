//
//  PresentedViewController.swift
//  CustomTransition
//
//  Created by naru on 2016/07/27.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit


class LocationStoriesViewController: StoriesViewController {
    
    var location:Location!
    
    
    override func deleteCurrentItem() {
        guard let cell = getCurrentCell() else { return }
        if let item = cell.getCurrentItem() {
            FirebaseService.removeItemFromLocation(item, completionHandler: {
                self.popStoryController(true)
            })
        }
    }
    
    override func showLocation(location:Location) {
        popStoryController(true)
    }
    
    override func showOptions() {
        print("DO WE GET HERE?")
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
            
            if item.toLocation {
                let storyAction: UIAlertAction = UIAlertAction(title: "Remove from \(location.getName())", style: .Destructive)
                { action -> Void in
                    FirebaseService.removeItemFromLocation(item, completionHandler: {
                        self.popStoryController(true)
                    })
                }
                actionSheet.addAction(storyAction)
            }
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
}

class StoriesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
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
            cell.enableMoreButton()
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

    }
    
    
    func appMovedToBackground() {
        print("App moved to background!")
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
        return cell
    }
    
    func popStoryController(animated:Bool) {
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(animated)
        }
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
    
    
    func showOptions() {
        print("DO WE GET HERE?")
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
            
            if item.toStory {
                let storyAction: UIAlertAction = UIAlertAction(title: "Remove from my Story", style: .Destructive)
                { action -> Void in
                    FirebaseService.removeItemFromStory(item, completionHandler: {
                        self.popStoryController(true)
                    })
                }
                actionSheet.addAction(storyAction)
            }
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
    
    func deleteCurrentItem() {
        guard let cell = getCurrentCell() else { return }
        if let item = cell.getCurrentItem() {
//            FirebaseService.removeItemFromLocation(item, completionHandler: {
//                self.popStoryController(true)
//            })
        }
    }
    
    func stopPreviousItem() {
        if let cell = getCurrentCell() {
            cell.pauseVideo()
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
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
