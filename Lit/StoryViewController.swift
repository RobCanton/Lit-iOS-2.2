//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import AVFoundation

class StoryViewController: UIViewController, StoreSubscriber, ItemDelegate {
    
    
    var locationIndex: Int?
    var location:Location?
    var imageView:UIImageView?
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    var videoView:UIView?
    var mainView:UIView?
    
    var authorInfoView: AuthorInfoView?
    var titleView: UILabel?
    var messageView: UIView?
    
    var progressIndicator: StoryProgressIndicator?
    
    var story:[StoryItem]?
    
    var isLoading = true
    
    var currentStoryItem:Int = -1
    var stepper:Int = 0
    
    var totalLength:Double = 0.0
    var currentProgress:Double = 0.0
    
    var timer:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView = UIView(frame: self.view.frame)
        mainView!.center = self.view.center
        self.view.addSubview(mainView!)
        imageView?.contentMode = .ScaleAspectFit
        imageView = UIImageView(frame: self.view.frame)
        imageView!.center = self.view.center
        
        mainView!.addSubview(imageView!)
        
        videoView = UIView(frame: self.view.frame)
        videoView!.center = self.view.center
        videoView!.backgroundColor = UIColor.blackColor()
        videoView!.hidden = true
        
        videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        
        playerLayer!.frame = self.view.bounds
        self.videoView!.layer.addSublayer(playerLayer!)
        
        titleView = UILabel(frame: CGRect(x: 12, y: self.view.frame.height - 52, width: self.view.frame.width, height: 32))
        titleView!.font = UIFont(name: "Avenir-Oblique", size: 18.0)
        titleView!.textColor = UIColor.whiteColor()
        titleView!.textAlignment = .Left
        
        self.view.addSubview(titleView!)
        
        progressIndicator = StoryProgressIndicator(frame: CGRect(x: 12, y: self.view.frame.height - 18, width: self.view.frame.width - 24, height: 2.0))
        
        self.view.addSubview(progressIndicator!)
        
        mainView!.addSubview(videoView!)
        
        authorInfoView = AuthorInfoView(frame: CGRect(x: 0, y:0,
            width: view.frame.width, height: 40))
        
        self.view.addSubview(authorInfoView!)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(mainViewTapped))
        mainView?.addGestureRecognizer(tapGestureRecognizer)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        mainView?.addGestureRecognizer(swipeDown)
        
        messageView = UIView(frame: CGRect(x: 12, y: 300, width: self.view.frame.width - 24, height: 100))
        let blurBG = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurBG.contentView.alpha = 0.4
        blurBG.frame = messageView!.bounds
        messageView?.addSubview(blurBG)
        //messageView?.alpha = 0.5
        
        //self.view.addSubview(messageView!)
        
    }
    
    func swipedDown(gesture:UIGestureRecognizer) {
        self.removePlayer()
        self.playerLayer?.removeFromSuperlayer()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
    }
    
    
    func newState(state: AppState) {
        print("New State Tingz")
        
        locationIndex = mainStore.state.storyViewIndex
        
        
        if locationIndex != -1 {
            let location = mainStore.state.locations[locationIndex!]
            print("Viewing story for : \(location.getKey())")
            titleView!.text = location.getName()
            
            if let story = location.getStory() {
                self.story = story
                progressIndicator?.createProgressIndicator(story)
                
                for item in story {
                    totalLength += item.getLength()!
                }
                
                // Load next 3, then from here load as each item passes
                loadNextChunk()
                loadNextChunk()
                loadNextChunk()
                showNextStoryItem()
            } else {
                FirebaseService.downloadLocationStory(locationIndex!)
            }
        }
    }
    
    func mainViewTapped(sender: UITapGestureRecognizer) {
        
        // show next story
        if !isLoading {
            if let _ = timer {
                timer?.fire()
            } else {
                showNextStoryItem()
            }
        } else {
            print("Tapped: isLoading")
        }
    }
    
    func showNextStoryItem() {
        if let _ = timer {
            timer?.invalidate()
            timer = nil
        }
        loadNextChunk()
        self.imageView!.image = nil
        self.removePlayer()
        self.progressIndicator?.deactivateIndicator(currentStoryItem)
        
        self.imageView!.image = nil
        
        
        if currentStoryItem >= 0 && currentStoryItem < story?.count {
            story![currentStoryItem].delegate = nil
        }
        currentStoryItem += 1
        
        if story?.count > 0 && currentStoryItem < story?.count {
            story![currentStoryItem].delegate = self
            authorInfoView?.setTime(story![currentStoryItem].getDateCreated()!)
            
            print("Content loaded already")
            presentContent()
        }
        else {
            self.removePlayer()
            self.playerLayer?.removeFromSuperlayer()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    func yo () {
        print("times up, show dat new story")
    }
    
    func presentContent() {
        isLoading = true
        let contentType = story![currentStoryItem].getContentType()
        if contentType == .Image {
            if let image = story![currentStoryItem].image {
                isLoading = false
                self.imageView?.image = image
                videoView?.hidden = true
                progressIndicator?.activateIndicator(currentStoryItem)
                timer?.invalidate()
                timer = nil
                timer = NSTimer.scheduledTimerWithTimeInterval(story![currentStoryItem].getLength()!, target: self, selector: "showNextStoryItem", userInfo: nil, repeats: false)
                if let user = story![currentStoryItem].getAuthor() {
                    authorLoaded(user)
                }
                
            }
        } else if contentType == .Video {
            if let filePath = story![currentStoryItem].filePath {
                isLoading = false
                let item = AVPlayerItem(URL: filePath)
                videoPlayer.replaceCurrentItemWithPlayerItem(item)
                videoPlayer.actionAtItemEnd = .Pause
                videoPlayer.play()
                videoView!.hidden = false
                progressIndicator?.activateIndicator(currentStoryItem)
                timer?.invalidate()
                timer = nil
                timer = NSTimer.scheduledTimerWithTimeInterval(story![currentStoryItem].getLength()!, target: self, selector: "showNextStoryItem", userInfo: nil, repeats: false)
                if let user = story![currentStoryItem].getAuthor() {
                    authorLoaded(user)
                }
            }
        }
    }
    
    func contentLoaded (contentType:ContentType) {
        print("Content loaded later")
        presentContent()

    }
    
    
    func authorLoaded(author:User) {
        print("AUTHOR: \(author.getDisplayName())")
        if story![currentStoryItem].getAuthorId() == author.getUserId() {
            authorInfoView?.setAuthor(author)
        }
    }
    
    func loadNextChunk() {
        if stepper >= 0 && stepper < story?.count {
            if let item = story?[stepper] {
                item.initiateDownload()
                stepper += 1
            }
        }
    }
    
    func removePlayer() {
        playerLayer?.player?.seekToTime(CMTimeMake(0, 1))
        playerLayer?.player?.pause()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}
