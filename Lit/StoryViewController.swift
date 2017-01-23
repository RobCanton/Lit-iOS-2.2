//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import AVFoundation
import NVActivityIndicatorView


public class StoryViewController: UICollectionViewCell, StoryProtocol {

    var viewIndex = 0
    
    func validIndex() -> Bool {
        if let items = story.items {
            return viewIndex >= 0 && viewIndex < items.count
        } else {
            return false
        }
    }
    
    var item:StoryItem?
    var tap:UITapGestureRecognizer!
    
    var longTap:UILongPressGestureRecognizer!
    
    var authorTappedHandler:((user:User)->())?
    var optionsTappedHandler:(()->())?
    var storyCompleteHandler:(()->())?
    
    var viewsTappedHandler:(()->())?
    
    func showOptions(){
        pauseStory()
        optionsTappedHandler?()
    }
    
    var playerLayer:AVPlayerLayer?
    var activityView:NVActivityIndicatorView!
    var currentProgress:Double = 0.0
    var timer:NSTimer?
    
    var totalTime:Double = 0.0
    
    var progressBar:StoryProgressIndicator?
    
    var shouldPlay = false
    
    var story:UserStory!
        {
        didSet {
            
            
            shouldPlay = false
            self.story.delegate = self
            story.determineState()
            
            
        }
    }
    
    func stateChange(state:UserStoryState) {
        switch state {
        case .NotLoaded:
            disableTap()
            self.activityView.stopAnimating()
            break
        case .LoadingItemInfo:
            disableTap()
            activityView.startAnimating()
            break
        case .ItemInfoLoaded:
            disableTap()
            itemsLoaded()
            break
        case .LoadingContent:
            disableTap()
            activityView.startAnimating()
            break
        case .ContentLoaded:

            contentLoaded()
            break
        }
    }
    
    func itemsLoaded() {
        
        self.activityView.stopAnimating()
        story.downloadStory()
        
        
    }
    
    func contentLoaded() {
        enableTap()
        self.activityView.stopAnimating()
        
        let screenWidth: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        
        let margin:CGFloat = 8.0
        progressBar?.removeFromSuperview()
        progressBar = StoryProgressIndicator(frame: CGRectMake(margin,margin,screenWidth - margin * 2,1.0))
        progressBar!.createProgressIndicator(story)
        contentView.addSubview(progressBar!)
        
        viewIndex = 0
        
        for item in story.items! {
        
            totalTime += item.getLength()
            
            if item.hasViewed() {
                viewIndex += 1
            }
        }
        
        if viewIndex >= story.items!.count{
            viewIndex = 0
        }
        
        
        self.setupItem()
        
        
    }
    
    func setupItem() {
        pauseVideo()
        
        guard let items = story.items else { return }
        
        if viewIndex < items.count {
            
            let item = items[viewIndex]
            self.item = item
            self.authorOverlay.setPostMetadata(item)
            if item.contentType == .Image {
                loadImageContent(item)
            } else if item.contentType == .Video {
                loadVideoContent(item)
            }
            
            let viewers = item.viewers
            if viewers.count == 1 {
                viewsButton.setTitle("1 view", forState: .Normal)
                viewsButton.hidden = false
            } else if viewers.count > 1 {
                viewsButton.setTitle("\(viewers.count) views", forState: .Normal)
                viewsButton.hidden = false
            } else {
                viewsButton.hidden = true
            }
            
            viewsButton.titleLabel?.sizeToFit()
            viewsButton.sizeToFit()
            
        } else {
            self.removeGestureRecognizer(tap)
            storyCompleteHandler?()
        }
        
    }
    
    func loadImageContent(item:StoryItem) {
        
        if let image = item.image {
            content.image = image
            if self.shouldPlay {
                self.setForPlay()
            }
        } else {
            story.downloadStory()
        }
    }
    
    func loadVideoContent(item:StoryItem) {
        /* CURRENTLY ASSUMING THAT IMAGE IS LOAD */
        if let image = item.image {
            content.image = image
            
        } else {
            content.loadImageUsingCacheWithURLString(item.downloadUrl.absoluteString, completion: { result in })
        }
        createVideoPlayer()
        if let videoData = loadVideoFromCache(item.key) {
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("temp/\(item.key).mp4")
            
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
            content.hidden = false
            videoContent.hidden = true
            story.downloadStory()
        }
    }
    
    func loadContent() {
        self.fadeCoverIn()
        self.activityView.startAnimating()
        story.downloadStory()
        
    }
    
    func setForPlay() {
        if story.state != .ContentLoaded {
            shouldPlay = true
            return
        }
        
        guard let item = self.item else {
            shouldPlay = true
            return }
        
        shouldPlay = false
        
        var itemLength = item.getLength()
        if item.contentType == .Image {
            videoContent.hidden = true
            
        } else if item.contentType == .Video {
            videoContent.hidden = false
            playVideo()
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }
        
        self.progressBar?.activateIndicator(viewIndex)
        killTimer()
        timer = NSTimer.scheduledTimerWithTimeInterval(itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
        
        let uid = mainStore.state.userState.uid
        if !item.hasViewed() && item.authorId != uid{
            item.viewers[uid] = 1
            FirebaseService.addView(item.getKey())
        }
    }
    
    func nextItem() {
        viewIndex += 1
        shouldPlay = true
        
        setupItem()
    }
    
    func prevItem() {
        if viewIndex > 0 {
            viewIndex -= 1
        }
        
        shouldPlay = true
        
        setupItem()
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
    
    func destroyVideoPlayer() {
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer?.player = nil
        self.playerLayer = nil
        videoContent.hidden = false
        
    }
    
    func getViews() {

    }
    
    func cleanUp() {
        destroyVideoPlayer()
        killTimer()
        progressBar?.resetAllProgressBars()
    }
    
    func playVideo() {
        self.playerLayer?.player?.play()
    }
    
    func pauseVideo() {
        self.playerLayer?.player?.pause()
    }
    
    func resetVideo() {
        self.playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        pauseVideo()
    }
    
    func pauseStory() {
        killTimer()
        self.resetVideo()
        progressBar?.resetActiveIndicator()
    }
    
    func getCurrentItem() -> StoryItem? {
        return story.items?[viewIndex]
    }
    
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func enableTap() {
        self.addGestureRecognizer(tap)
    }
    
    func disableTap() {
        self.removeGestureRecognizer(tap)
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.hidden = false
        videoContent.hidden = true
    }
    
    func yo() {
        killTimer()
        guard let item = item else { return }
        if item.contentType == .Video {
            
            guard let time = playerLayer?.player?.currentTime() else { return }
            self.pauseVideo()
            
            
            guard let currentItem = playerLayer?.player?.currentItem else { return }
            
            let asset = currentItem.asset
            if let image = generateVideoStill(asset, time: time) {
                content.image = image
            }
            
        }
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        let tappedPoint = gesture.locationInView(self)
        let width = self.bounds.width
        if tappedPoint.x < width * 0.25 {
            prevItem()
            prevView.alpha = 1.0
            UIView.animateWithDuration(0.25, animations: {
                self.prevView.alpha = 0.0
            })
        } else {
           nextItem()
        }
    }

    func fadeCoverIn() {
        UIView.animateWithDuration(0.25, animations: {
            self.fadeCover.alpha = 0.5
        })
    }
    
    func fadeCoverOut() {
        UIView.animateWithDuration(0.25, animations: {
            self.fadeCover.alpha = 0.0
        })
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var moreTapped:UITapGestureRecognizer!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.fadeCover)
        self.contentView.addSubview(self.prevView)
        self.contentView.addSubview(self.authorOverlay)
        self.contentView.addSubview(self.viewsButton)
        self.contentView.addSubview(self.moreButton)
        

        self.fadeCover.alpha = 0.0
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
//        longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTapped))
//        longTap.minimumPressDuration = 0.5
//        longTap.numberOfTapsRequired = 1
        
        moreTapped = UITapGestureRecognizer(target: self, action: #selector(showOptions))
        self.moreButton.addGestureRecognizer(moreTapped)
        self.moreButton.userInteractionEnabled = true
        
        self.viewsButton.userInteractionEnabled = true
        self.viewsButton.addTarget(self, action: #selector(viewsTapped), forControlEvents: .TouchUpInside)
        
        activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,50,50), type: .BallScaleMultiple)
        activityView.center = self.center
        self.contentView.addSubview(activityView)
        
    }
    
    func viewsTapped() {
        print("Views tapped")
        viewsTappedHandler?()
    }
    
    func longTapped(recognizer:UILongPressGestureRecognizer) {
        print("Long tapped")
        if recognizer.state == .Began {
            pauseStory()
        } else {
            setForPlay()
        }
    }
    
    
    public lazy var content: UIImageView = {

        let view: UIImageView = UIImageView(frame: self.contentView.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.clearColor()
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
    
    public lazy var fadeCover: UIView = {
        
        let view: UIImageView = UIImageView(frame: self.contentView.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.backgroundColor = UIColor.blackColor()
        return view
    }()
    
    public lazy var prevView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width * 0.4, height: self.bounds.height))

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        let dark = UIColor(white: 0.0, alpha: 0.42)
        gradient.colors = [dark.CGColor, UIColor.clearColor().CGColor]
        view.layer.insertSublayer(gradient, atIndex: 0)
        view.userInteractionEnabled = false
        view.alpha = 0.0
        return view
    }()
    
    lazy var authorOverlay: PostAuthorView = {
        let margin:CGFloat = 2.0
        var authorView = UINib(nibName: "PostAuthorView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! PostAuthorView
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        
        authorView.frame = CGRect(x: margin, y: margin + 6.0, width: width, height: authorView.frame.height)
        authorView.authorTappedHandler = self.authorTappedHandler
        return authorView
    }()
    
//    lazy var socialView: SocialView = {
//        var socialView = UINib(nibName: "SocialView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! SocialView
//        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
//        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
//        
//        socialView.frame = CGRect(x: 0, y:height - socialView.frame.height, width: width, height: socialView.frame.height)
//        return socialView
//    }()
    
    lazy var viewsButton: UIButton = {
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let button = UIButton(frame: CGRectMake(12,height - 36,40,40))
        button.titleLabel!.font = UIFont.init(name: "AvenirNext-Medium", size: 16)
        button.tintColor = UIColor.whiteColor()
        button.alpha = 0.70
        return button
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
