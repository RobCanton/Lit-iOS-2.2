//
//  GalleryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//


import UIKit
import AVFoundation
import NVActivityIndicatorView


class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {
    
    
    var photos = [StoryItem]()
    var uid:String!
    var tabBarRef:PopUpTabBarController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .None
        
        
        self.navigationItem.leftBarButtonItem = self.backItem
        
        self.view.backgroundColor = UIColor.blackColor()
        
        
        collectionView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.collectionView)
    
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarRef.setTabBarVisible(false, animated: true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appMovedToBackground), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        
        UIView.animateWithDuration(0.15, animations: {
            self.statusBarShouldHide = true
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                }
            }
        }
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PresentedCollectionViewCell {
            cell.setForPlay()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        tabBarRef.setTabBarVisible(true, animated: true)
        
        for cell in collectionView.visibleCells() as! [PresentedCollectionViewCell] {
            cell.cleanUp()
        }
    }
    
    
    func deleteCurrentPost() {
        let uid = mainStore.state.userState.uid
        let indexPath = self.collectionView.indexPathsForVisibleItems().first!
        let item = photos[indexPath.item]
        
        let ref = FirebaseService.ref.child("users/uploads/\(uid)/\(item.getKey())")
        ref.removeValueWithCompletionBlock({ error, ref in
            let deleteRef = FirebaseService.ref.child("api/requests/upload/delete/\(item.getKey())")
            deleteRef.setValue(uid, withCompletionBlock: { error, ref in
                self.navigationController?.popViewControllerAnimated(true)
            })
        })
    }
    
    // MARK: Elements
    
    weak var transitionController: TransitionController!
    
    lazy var collectionView: UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = self.view.bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        
        let collectionView: UICollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.registerClass(PresentedCollectionViewCell.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        return collectionView
    }()
    
    func appMovedToBackground() {

        popStoryController(false)
    }
    
    func popStoryController(animated:Bool) {
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)

        navigationController?.popViewControllerAnimated(animated)
    }
    
    
    lazy var backItem: UIBarButtonItem = {
        let item: UIBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: self, action: #selector(onBackItemClicked(_:)))
        return item
    }()
    
    func showOptions() {
        guard let cell = getCurrentCell() else { return }
        guard let item = cell.storyItem else {
            cell.setForPlay()
            return }
        
        if uid == mainStore.state.userState.uid {
            
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
                    let storyAction: UIAlertAction = UIAlertAction(title: "Remove from my profile", style: .Destructive)
                    { action -> Void in
                        FirebaseService.removeItemFromProfile(item, completionHandler: {
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
    
    
    func deleteCurrentItem() {
        guard let cell = getCurrentCell() else { return }
        let uid = mainStore.state.userState.uid
        let key = cell.storyItem.getKey()
        let ref = FirebaseService.ref.child("users/uploads/\(uid)/\(key)")
        ref.removeValueWithCompletionBlock({ error, ref in
            self.popStoryController(true)
        })
    
    }
    
    func getCurrentCell() -> PresentedCollectionViewCell? {
        if let cell = collectionView.visibleCells().first as? PresentedCollectionViewCell {
            return cell
        }
        return nil
    }
    
    

    
    
    // MARK: CollectionView Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: PresentedCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("presented_cell", forIndexPath: indexPath) as! PresentedCollectionViewCell
        cell.contentView.backgroundColor = UIColor.blackColor()
        
        let item = photos[indexPath.item]
        cell.storyItem = item
        cell.optionsTappedHandler = showOptions
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! PresentedCollectionViewCell
        cell.cleanUp()
    }
    
    // MARK: Actions
    
    func onCloseButtonClicked(sender: AnyObject) {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onBackItemClicked(sender: AnyObject) {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }
    
    func onPushItemClicked(sender: AnyObject) {
        
        self.navigationController?.delegate = self
    }
    
    // MARK: Gesture Delegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    

    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        
        
        if let cell = getCurrentCell() {
            cell.setForPlay()
        }
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

extension GalleryViewController: View2ViewTransitionPresented {
    
    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }
    
    func destinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
        let cell: PresentedCollectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath) as! PresentedCollectionViewCell
        cell.prepareForTransition(isPresenting)
        return view
    }
    
    func prepareDestinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            
            let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
            
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    
}

public class PresentedCollectionViewCell: UICollectionViewCell, ItemDelegate {
    
    var playerLayer:AVPlayerLayer?
    var activityView:NVActivityIndicatorView!
    
    var optionsTappedHandler:(()->())?
    
    func showOptions() {
        pauseVideo()
        optionsTappedHandler?()
    }
    
    var shouldPlay = false
    
    var storyItem:StoryItem! {
        didSet {
            shouldPlay = false
            storyItem.delegate = self
            setItem()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.moreButton)
        videoContent.hidden = true
        
        self.moreButton.addTarget(self, action: #selector(showOptions), forControlEvents: .TouchUpInside)
        
        activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,50,50), type: .BallScaleMultiple)
        activityView.center = self.center
        self.contentView.addSubview(activityView)
    }

    func setItem() {
        if let image = storyItem.image {
            self.content.image = image
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            activityView?.startAnimating()
            storyItem.download()
        }
        
        if storyItem.contentType == .Video {
            
            if let videoData = loadVideoFromCache(storyItem.key) {
                createVideoPlayer()
                
                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                let filePath = documentsURL.URLByAppendingPathComponent("temp/\(storyItem.key).mp4")
                
                try! videoData.writeToURL(filePath, options: NSDataWritingOptions.DataWritingAtomic)
                
                let asset = AVAsset(URL: filePath)
                asset.loadValuesAsynchronouslyForKeys(["duration"], completionHandler: {
                    dispatch_async(dispatch_get_main_queue(), {
                        let item = AVPlayerItem(asset: asset)
                        self.playerLayer?.player?.replaceCurrentItemWithPlayerItem(item)
                        
                        if self.shouldPlay {
                            self.setForPlay()
                        }
                    })
                })
                
            } else {
                 activityView?.startAnimating()
                storyItem.download()
            }
        }

    }

    
    func itemDownloaded() {
        activityView?.stopAnimating()
        setItem()
    }
    
    func setForPlay(){
        
        if storyItem.needsDownload() {
            
            shouldPlay = true
            return
        }
        
        shouldPlay = false
        
        if storyItem.contentType == .Image {
            videoContent.hidden = true
            
        } else if storyItem.contentType == .Video {
            videoContent.hidden = false
            playVideo()
            loopVideo()
        }
    }
    
    func loopVideo() {
        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
            self.playerLayer?.player?.seekToTime(kCMTimeZero)
            self.playerLayer?.player?.play()
        }
    }
    
    
    func createVideoPlayer() {
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: AVPlayer())
            playerLayer!.player?.actionAtItemEnd = .Pause
            playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            playerLayer!.frame = videoContent.bounds
            self.videoContent.layer.addSublayer(playerLayer!)
        }
    }
    
    func playVideo() {
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.hidden = false
        videoContent.hidden = true
    }
    
    func cleanUp() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        content.image = nil
        destroyVideoPlayer()
    }
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.hidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let margin: CGFloat = 2.0
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.blackColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame = CGRectMake(0,0,width, height + 0)
        let view: UIImageView = UIImageView(frame: frame)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.clearColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
    
    lazy var moreButton: UIButton = {
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let button = UIButton(frame: CGRectMake(width - 40,height - 40,40,40))
        button.setImage(UIImage(named: "more2"), forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.alpha = 1.0
        return button
    }()
    
    
    
    
}

