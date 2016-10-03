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
    
    var story = [StoryItem]()
    
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
    
    var postKeys = [String]()
    
    func newState(state: AppState) {
        
        locationIndex = mainStore.state.storyViewIndex
        
        story = [StoryItem]()
        if locationIndex != -1 {
            let location = mainStore.state.locations[locationIndex!]
            print("Viewing story for : \(location.getKey())")
            
            postKeys = location.getPostKeys()
            
            FirebaseService.downloadStory(postKeys, completionHandler: { story in
                self.story = story
                self.prepareStory()
            })
        }
    }
    
    var storyItemView:StoryItemViewController!
    
    func prepareStory() {
        print("Preparing story")
        
        
        storyItemView = StoryItemViewController(nibName: "StoryItemViewController", bundle: nil)
        storyItemView.view.frame = mainView!.bounds
        addChildViewController(storyItemView)
        mainView!.addSubview(storyItemView.view)
        storyItemView.didMoveToParentViewController(self)
//        
        progressIndicator = StoryProgressIndicator(frame: CGRect(x: 12, y: 8, width: view.frame.width - 24, height: 3.0))
        view.addSubview(progressIndicator!)
        
        progressIndicator!.createProgressIndicator(story)
        
        storyItemView.displayLocation(mainStore.state.locations[locationIndex!])
        
        loadNextChunk()
        setNextStoryItem()

    }
    
    func setNextStoryItem() {
        if let _ = timer {
            timer!.invalidate()
            timer = nil
        }
        
        loadNextChunk()
        progressIndicator!.deactivateIndicator(currentStoryItem)
        
        if currentStoryItem >= 0 && currentStoryItem < story.count {
            story[currentStoryItem].delegate = nil
        }
        currentStoryItem += 1
        
        if story.count > 0 && currentStoryItem < story.count {
            storyItemView.setStoryItem(story[currentStoryItem], _delegate: self)
        }
        else {
            //self.removePlayer()
            //self.playerLayer?.removeFromSuperlayer()
            
            //KILL PLAYER
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mainViewTapped(sender: UITapGestureRecognizer) {
        
        // show next story
        if !storyItemView.isLoading {
            if let _ = timer {
                timer?.fire()
            } else {
                setNextStoryItem()
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
        
        
        if currentStoryItem >= 0 && currentStoryItem < story.count {
            story[currentStoryItem].delegate = nil
        }
        currentStoryItem += 1
        
        if story.count > 0 && currentStoryItem < story.count {
            authorInfoView?.setTime(story[currentStoryItem].getDateCreated()!)
            
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
        let contentType = story[currentStoryItem].getContentType()
        if contentType == .Image {
            if let image = story[currentStoryItem].image {
                isLoading = false
                self.imageView?.image = image
                videoView?.hidden = true
                progressIndicator?.activateIndicator(currentStoryItem)
                timer?.invalidate()
                timer = nil
                timer = NSTimer.scheduledTimerWithTimeInterval(story[currentStoryItem].getLength()!, target: self, selector: "showNextStoryItem", userInfo: nil, repeats: false)
                if let user = story[currentStoryItem].getAuthor() {
                    //authorLoaded(user)
                }
                
            }
        } else if contentType == .Video {
            if let filePath = story[currentStoryItem].filePath {
                isLoading = false
                let item = AVPlayerItem(URL: filePath)
                videoPlayer.replaceCurrentItemWithPlayerItem(item)
                videoPlayer.actionAtItemEnd = .Pause
                videoPlayer.play()
                videoView!.hidden = false
                progressIndicator?.activateIndicator(currentStoryItem)
                timer?.invalidate()
                timer = nil
                timer = NSTimer.scheduledTimerWithTimeInterval(story[currentStoryItem].getLength()!, target: self, selector: "showNextStoryItem", userInfo: nil, repeats: false)
                if let user = story[currentStoryItem].getAuthor() {
                    //authorLoaded(user)
                }
            }
        }
    }
    
    func contentLoaded () {
        progressIndicator?.activateIndicator(currentStoryItem)
        
        timer?.invalidate()
        timer = nil
        timer = NSTimer.scheduledTimerWithTimeInterval(story[currentStoryItem].getLength()!, target: self, selector: "setNextStoryItem", userInfo: nil, repeats: false)
    }
    
    
    func authorLoaded() {
    }
    
    func loadNextChunk() {
        if stepper >= 0 && stepper < story.count {
            let item = story[stepper]
            item.initiateDownload()
            stepper += 1

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
