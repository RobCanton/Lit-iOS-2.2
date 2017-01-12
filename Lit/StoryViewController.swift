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
import SwiftMessages


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
    
    var authorTappedHandler:((user:User)->())?
    var optionsTappedHandler:(()->())?
    var storyCompleteHandler:(()->())?
    
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
            
//            enableTap()
//            viewIndex = 0
//            setupItem()
//            
//        
//            
            let screenWidth: CGFloat = (UIScreen.mainScreen().bounds.size.width)
            
            let margin:CGFloat = 8.0
            progressBar?.removeFromSuperview()
            progressBar = StoryProgressIndicator(frame: CGRectMake(margin,margin,screenWidth - margin * 2,1.0))
            progressBar!.createProgressIndicator(story)
            contentView.addSubview(progressBar!)
            
            
            for item in story.items! {
                totalTime += item.getLength()
            }
            
            
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
        
        let screenWidth: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        
        let margin:CGFloat = 8.0
        progressBar?.removeFromSuperview()
        progressBar = StoryProgressIndicator(frame: CGRectMake(margin,margin,screenWidth - margin * 2,1.0))
        progressBar!.createProgressIndicator(story)
        contentView.addSubview(progressBar!)
        
        
        for item in story.items! {
            totalTime += item.getLength()
        }
    }
    
    func contentLoaded() {
        enableTap()
        self.activityView.stopAnimating()
        self.setupItem()
    }
    
    func setupItem() {
        print("SETUP ITEM: \(viewIndex)")
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
        print("VIEW INDEX: \(viewIndex) | SHOULD PLAY: \(shouldPlay)")
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
    }
    
    func nextItem() {
        print("NEXT ITEM: \(viewIndex) +1")
        viewIndex += 1
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
        print("PAUSE STORY")
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
        nextItem()
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
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.fadeCover)
        self.contentView.addSubview(self.authorOverlay)
        self.contentView.addSubview(self.statsView)
        self.contentView.addSubview(self.moreButton)
        
        self.moreButton.addTarget(self, action: #selector(showOptions), forControlEvents: .TouchUpInside)
        
        self.fadeCover.alpha = 0.0
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,50,50), type: .BallScaleMultiple)
        let centerX = (UIScreen.mainScreen().bounds.size.width) / 2
        let centerY = (UIScreen.mainScreen().bounds.size.height) / 2
        activityView.center = CGPointMake(centerX, centerY)
        self.contentView.addSubview(activityView)
        
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
        let frame = CGRectMake(0,-6,width, height + 12)
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
    
    lazy var authorOverlay: PostAuthorView = {
        let margin:CGFloat = 2.0
        var authorView = UINib(nibName: "PostAuthorView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! PostAuthorView
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        
        authorView.frame = CGRect(x: margin, y: margin + 8.0, width: width, height: authorView.frame.height)
        authorView.authorTappedHandler = self.authorTappedHandler
        return authorView
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
    

    
    lazy var statsView: PostStatsView = {

        var view = UINib(nibName: "PostStatsView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! PostStatsView
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        
        view.frame = CGRect(x: 0, y: height - view.frame.height, width: width, height: view.frame.height)
        return view
    }()
}
