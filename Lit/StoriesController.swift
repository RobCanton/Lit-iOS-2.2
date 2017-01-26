//
//  StoriesController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//
import UIKit
import Whisper
import ISHPullUp

class StoriesController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var label:UILabel!
    var userStories = [UserStory]()
    
    var collectionView:UICollectionView!
    var currentIndex:NSIndexPath!
    var delegate: StoryPullUpProtocol!
    
    var pullUpController:PullUpController!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        automaticallyAdjustsScrollViewInsets = false
    }
    
    func playCurrentCell() {
        getCurrentCell()?.setForPlay()
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
        
        for cell in collectionView.visibleCells() as! [StoryViewController] {
            cell.cleanUp()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.redColor()

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.mainScreen().bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        
        collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView.registerClass(StoryViewController.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.redColor()
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
        popStoryController(false)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.mainScreen().bounds.size
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userStories.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: StoryViewController = collectionView.dequeueReusableCellWithReuseIdentifier("presented_cell", forIndexPath: indexPath) as! StoryViewController
        cell.contentView.backgroundColor = UIColor.blackColor()
        cell.itemSetHandler = delegate?.setCurrentItem
        cell.authorOverlay.authorTappedHandler = showAuthor
        cell.authorOverlay.locationTappedHandler = showLocation
        cell.optionsTappedHandler = showOptions
        cell.storyCompleteHandler = storyComplete
        cell.viewsTappedHandler = showViewers
        cell.story = userStories[indexPath.item]
        
        return cell
    }
    
    func popStoryController(animated:Bool) {
        pullUpController.parent.popStoryController(true)
    }
    
    
    func storyComplete() {
        popStoryController(true)
    }
    
    func showAuthor(user:User) {
    }
    
    func showLocation(location:Location) {

    }
    
    func showViewers() {

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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        
        let newItem = Int(xOffset / self.collectionView.frame.width)
        currentIndex = NSIndexPath(forItem: newItem, inSection: 0)
        
        playCurrentCell()
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! StoryViewController
        cell.cleanUp()
    }
}
