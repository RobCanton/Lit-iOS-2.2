//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import AVFoundation

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
            self.addGestureRecognizer(tap)
            viewIndex = 0
            setItem()
        }
    }
    
    func setItem() {
        if viewIndex < story.getItems().count {
            let item = story.getItems()[viewIndex]
            self.item = item
            if item.contentType == .Image {
                loadImageContent(item)
            } else if item.contentType == .Video {
                loadVideoContent(item)
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
            content.hidden = true
            videoContent.hidden = false
            playVideo()
        }
    }
    
    func loadVideoContent(item:StoryItem) {
        if let videoData = item.videoData {
            
            content.image = item.image!
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("user_videos\(item.key).mp4")
            
            try! videoData.writeToURL(filePath, options: NSDataWritingOptions.DataWritingAtomic)
            let item = AVPlayerItem(URL: filePath)
            videoPlayer.replaceCurrentItemWithPlayerItem(item)
            playerLayer = AVPlayerLayer(player: videoPlayer)
            
            playerLayer!.player?.play()
            playerLayer!.player?.actionAtItemEnd = .Pause
            

        }
    }
    
    func loopVideo(videoPlayer: AVPlayer) {
        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
            videoPlayer.seekToTime(kCMTimeZero)
            videoPlayer.play()
        }
    }
    
    var videoPlayer:AVPlayer!
    var playerLayer:AVPlayerLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        
        playerLayer!.frame = videoContent.frame
        self.videoContent.layer.addSublayer(playerLayer!)
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
    }
    
    func playVideo() {
        videoPlayer.play()
    }
    
    func prepareForTransition(isPresenting:Bool) {
        content.hidden = false
        videoContent.hidden = true
        if !isPresenting {
            print("Disappearing, update screenshot")
            if item!.contentType == .Video {
                print("Pause Video")
                videoPlayer.pause()
                let time = videoPlayer.currentTime()
                videoPlayer.pause()
                let asset = videoPlayer.currentItem!.asset
                if let image = generateVideoStill(asset, time: time) {
                    content.image = image
                }
            }
        }
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        viewIndex += 1
        setItem()
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
        view.backgroundColor = UIColor.blackColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
    
    public lazy var videoContent: UIView = {

        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIView = UIView(frame: frame)
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.0)
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
}
