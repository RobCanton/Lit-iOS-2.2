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
    var story:Story!
    {
        didSet {

            if story.getItems().count == 0 { return }
            enableTap()
            viewIndex = 0
            setupItem()
        }
    }
    
    var videoPlayer:AVPlayer!
    var playerLayer:AVPlayerLayer!
    
    var activityView:NVActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.3)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.fadeCover)
        fadeCover.hidden = true
        
        self.fadeCover.alpha = 0.0
        
        videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer!.player?.actionAtItemEnd = .Pause
        
        playerLayer!.frame = videoContent.frame
        self.videoContent.layer.addSublayer(playerLayer!)
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        activityView = NVActivityIndicatorView(frame: CGRectMake(0,0,30,30))
        let centerX = (UIScreen.mainScreen().bounds.size.width) / 2
        let centerY = (UIScreen.mainScreen().bounds.size.height) / 2
        activityView.center = CGPointMake(centerX, centerY)
        self.contentView.addSubview(activityView)
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
    
    func cleanUpPreviousItem() {
        let prevIndex = viewIndex - 1
        if prevIndex >= 0 {
            let prevItem = story.getItems()[prevIndex]
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("temp/\(prevItem.key).mp4")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(filePath)
                print("Video deleted")
                
            }
            catch let error as NSError {
                return print("Error \(error)")
            }
        }
    }
    
    func setupItem() {
        if viewIndex < story.getItems().count {
            let item = story.getItems()[viewIndex]
            self.item = item
            if item.contentType == .Image {
                loadImageContent(item)
                self.setForPlay()
            } else if item.contentType == .Video {
                loadVideoContent(item, completion: {
                    self.setForPlay()
                })
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
    
    func setForPlay() {
        guard let item = self.item else {return}
        if item.contentType == .Image {
            content.hidden = false
            videoContent.hidden = true
            
        } else if item.contentType == .Video {
            if videoPlayer.currentItem != nil {
                content.hidden = true
                videoContent.hidden = false
                playVideo()
                
            }
        }
    }
    
    func loadVideoContent(item:StoryItem, completion:()->()) {
        /* CURRENTLY ASSUMING THAT IMAGE IS LOAD */
        if let image = item.image {
            content.image = image
        } else {
            content.loadImageUsingCacheWithURLString(item.downloadUrl.absoluteString, completion: { result in })
        }
        if let videoData = loadVideoFromCache(item.key) {
            print("VIDEO PULLED FROM CACHE")
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("temp/\(item.key).mp4")
            
            try! videoData.writeToURL(filePath, options: NSDataWritingOptions.DataWritingAtomic)
            
            
            let asset = AVAsset(URL: filePath)
            asset.loadValuesAsynchronouslyForKeys(["duration"], completionHandler: {
                dispatch_async(dispatch_get_main_queue(), {
                    let item = AVPlayerItem(asset: asset)
                    self.videoPlayer.replaceCurrentItemWithPlayerItem(item)
                    completion()
                })
            })
        } else {
            print("NEEDS DOWNLOAD")
            content.hidden = false
            videoContent.hidden = true
            disableTap()
            self.fadeCoverIn()
            self.activityView.startAnimating()
            story.downloadStory({ complete in
                if complete {
                    self.loadVideoContent(item, completion: {
                        self.activityView.stopAnimating()
                        self.enableTap()
                        self.fadeCoverOut()
                        completion()
                    })
                }
            })
        }
    }
    
    func loopVideo(videoPlayer: AVPlayer) {
        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
            videoPlayer.seekToTime(kCMTimeZero)
            videoPlayer.play()
        }
    }
    
    func playVideo() {
        videoPlayer.play()
        print("PLAY DUH VIDEO!")
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
        if !isPresenting {
            print("Disappearing, update screenshot")
            if item!.contentType == .Video {
                print("Pause Video")
                let time = videoPlayer.currentTime()
                videoPlayer.pause()
                if let currentItem = videoPlayer.currentItem {
                    let asset = currentItem.asset
//                    if let image = generateVideoStill(asset, time: time) {
//                        content.image = image
//                    }
                }
            }
        }
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        viewIndex += 1
        setupItem()
        print("Show next item")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {

        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.3)
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {

        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIView = UIView(frame: frame)
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
    
    public lazy var fadeCover: UIView = {
        
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIView = UIView(frame: frame)
        view.backgroundColor = UIColor.blackColor()
        return view
    }()
}
