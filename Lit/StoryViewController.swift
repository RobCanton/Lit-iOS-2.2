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

protocol StoryViewDelegate {
    func storyComplete()
}

public class StoryViewController: UICollectionViewCell {

    var viewIndex = 0
    var delegate:StoryViewDelegate?
    
    var item:StoryItem?
    var tap:UITapGestureRecognizer!
    
    var authorTappedHandler:((user:User)->())?
    
    
    var playerLayer:AVPlayerLayer?
    var activityView:NVActivityIndicatorView!
    var currentProgress:Double = 0.0
    var timer:NSTimer?
    
    var totalTime:Double = 0.0
    
    var progressBar:StoryProgressIndicator?
    
    var story:Story!
        {
        didSet {
            
            if story.getItems().count == 0 { return }
            enableTap()
            viewIndex = 0
            setupItem({})
            let screenWidth: CGFloat = (UIScreen.mainScreen().bounds.size.width)
            let screenHeight: CGFloat = (UIScreen.mainScreen().bounds.size.height)
            let width: CGFloat = screenWidth
            let height: CGFloat = 2.0
            
            progressBar?.removeFromSuperview()
            progressBar = StoryProgressIndicator(frame: CGRectMake(0,0,width,height))
            progressBar!.createProgressIndicator(story)
            contentView.addSubview(progressBar!)
            
            for item in story.getItems() {
                totalTime += item.getLength()
            }
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.fadeCover)
        self.contentView.addSubview(self.authorOverlay)
        
        self.fadeCover.alpha = 0.0
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,50,50), type: .BallScaleMultiple)
        let centerX = (UIScreen.mainScreen().bounds.size.width) / 2
        let centerY = (UIScreen.mainScreen().bounds.size.height) / 2
        activityView.center = CGPointMake(centerX, centerY)
        self.contentView.addSubview(activityView)
    
    }
    
    func setupItem(completion:()->()) {
        killTimer()
        pauseVideo()
        if viewIndex < story.getItems().count {
            let item = story.getItems()[viewIndex]
            self.item = item
            self.authorOverlay.setPostMetadata(item)
            if item.contentType == .Image {
                loadImageContent(item)
                completion()
            } else if item.contentType == .Video {
                loadVideoContent(item, completion: completion)
            }
            
        } else {
            self.removeGestureRecognizer(tap)
            delegate?.storyComplete()
        }
        
    }
    
    func loadImageContent(item:StoryItem) {
        if let image = item.image {
            content.image = image
        }
    }
    
    func loadVideoContent(item:StoryItem, completion:()->()) {
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
                    completion()
                })
            })
        } else {
            content.hidden = false
            videoContent.hidden = true
            disableTap()
            self.fadeCoverIn()
            self.activityView.startAnimating()
            story.downloadStory({ complete in
                if complete {
                    
                    self.setupItem({
                        self.activityView.stopAnimating()
                        self.enableTap()
                        self.fadeCoverOut()
                        self.setForPlay()
                    })
                }
            })
        }
    }
    

    
    func setForPlay() {
        guard let item = self.item else { return }
        
        guard !item.needsDownload() else { return }
        
        var itemLength = item.getLength()
        if item.contentType == .Image {
            //content.hidden = false
            videoContent.hidden = true
            
        } else if item.contentType == .Video {
            //content.hidden = true
            videoContent.hidden = false
            playVideo()
            if let currentItem = playerLayer?.player?.currentTime() {
                itemLength -= currentItem.seconds
            }
        }
        self.progressBar?.activateIndicator(viewIndex)
        timer = NSTimer.scheduledTimerWithTimeInterval(itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
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
        if isPresenting {
            
        } else {
            killTimer()
            if item!.contentType == .Video {
                
                guard let time = playerLayer?.player?.currentTime() else { return }
                self.pauseVideo()
                
                
                guard let currentItem = playerLayer?.player?.currentItem else { return }
                
                let asset = currentItem.asset
                if let image = generateVideoStill(asset, time: time) {
                    content.image = image
                }

            }
        }
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        nextItem()
    }
    
    func nextItem() {
        viewIndex += 1
        setupItem(self.setForPlay)
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
        view.backgroundColor = UIColor.clearColor()
        view.backgroundColor = UIColor.blackColor()
        return view
    }()
    
    lazy var authorOverlay: PostAuthorView = {
        let margin:CGFloat = 3.0
        var authorView = UINib(nibName: "PostAuthorView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! PostAuthorView
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        
        authorView.frame = CGRect(x: margin, y: margin + 2.0, width: width, height: authorView.frame.height)
        authorView.authorTappedHandler = self.authorTappedHandler
        return authorView
    }()
//    
//    lazy var progressBar: StoryProgressIndicator = {
//        let screenWidth: CGFloat = (UIScreen.mainScreen().bounds.size.width)
//        let screenHeight: CGFloat = (UIScreen.mainScreen().bounds.size.height)
//        let width: CGFloat = screenWidth
//        let height: CGFloat = 2.0
//        
//        let bar = StoryProgressIndicator(frame: CGRectMake(0,0,width,height))
//        
//        return bar
//    }()
}
