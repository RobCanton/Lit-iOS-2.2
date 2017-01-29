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
import Firebase


public class StoryViewController: UICollectionViewCell, StoryProtocol {

    var viewIndex = 0
    
    func validIndex() -> Bool {
        if let items = story.items {
            return viewIndex >= 0 && viewIndex < items.count
        } else {
            return false
        }
    }
    
    var commentsRef:FIRDatabaseReference?
    
    var item:StoryItem?
    var tap:UITapGestureRecognizer!
    
    var longTap:UILongPressGestureRecognizer!
    
    var authorTappedHandler:((uid:String)->())?
    var optionsTappedHandler:(()->())?
    var storyCompleteHandler:(()->())?
    
    var viewsTappedHandler:(()->())?
    
    var itemSetHandler:((item:StoryItem)->())?
    
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
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardWillAppear), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardWillDisappear), name: UIKeyboardWillHideNotification, object: nil)
            
            
        }
    }
    
    func stateChange(state:UserStoryState) {
        switch state {
        case .NotLoaded:
            disableTap()
            animateIndicator()
            break
        case .LoadingItemInfo:
            disableTap()
            animateIndicator()
            break
        case .ItemInfoLoaded:
            disableTap()
            animateIndicator()
            story.downloadStory()
            break
        case .LoadingContent:
            disableTap()
            animateIndicator()
            break
        case .ContentLoaded:
            print("ContentLoaded")
            stopIndicator()
            contentLoaded()
            break
        }
    }
    var animateInitiated = false
    
    func animateIndicator() {
        if !animateInitiated {
            animateInitiated = true
            dispatch_async(dispatch_get_main_queue(), {
                if self.story.state != .ContentLoaded {
                    self.activityView.startAnimating()
                }
            })
        }
    }
    
    func stopIndicator() {
        if activityView.animating {
            dispatch_async(dispatch_get_main_queue(), {
                self.activityView.stopAnimating()
                self.animateInitiated = false
            })
        }
    }
    
    
    func contentLoaded() {
        enableTap()
        
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
            itemSetHandler?(item: item)
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
            
            commentsView.setTableComments(item.comments, animated: false)
            
            commentsRef?.removeAllObservers()
            commentsRef = FirebaseService.ref.child("uploads/\(item.getKey())/comments")

            if let lastItem = item.comments.last {
                let lastKey = lastItem.getKey()
                let ts = lastItem.getDate().timeIntervalSince1970 * 1000
                commentsRef?.queryOrderedByChild("timestamp").queryStartingAtValue(ts).observeEventType(.ChildAdded, withBlock: { snapshot in
                    let key = snapshot.key
                    if key != lastKey {
                        let author = snapshot.value!["author"] as! String
                        let text = snapshot.value!["text"] as! String
                        let timestamp = snapshot.value!["timestamp"] as! Double
                        
                        let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                        item.addComment(comment)
                        self.commentsView.setTableComments(item.comments, animated: true)
                    }
                })
            } else {
                commentsRef?.observeEventType(.ChildAdded, withBlock: { snapshot in
                    let key = snapshot.key
                    let author = snapshot.value!["author"] as! String
                    let text = snapshot.value!["text"] as! String
                    let timestamp = snapshot.value!["timestamp"] as! Double
                    
                    let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                    item.addComment(comment)
                    self.commentsView.setTableComments(item.comments, animated: true)
                })
            }
        } else {
            self.removeGestureRecognizer(tap)
            storyCompleteHandler?()
        }
        
    }
    
    func loadImageContent(item:StoryItem) {
        
        if let image = item.image {
            content.image = image
            self.playerLayer?.player?.replaceCurrentItemWithPlayerItem(nil)
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
            return story.downloadStory()
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
        textView.userInteractionEnabled = true
        moreButton.userInteractionEnabled = true
        killTimer()
        timer = NSTimer.scheduledTimerWithTimeInterval(itemLength, target: self, selector: #selector(nextItem), userInfo: nil, repeats: false)
        
        let uid = mainStore.state.userState.uid
        if !item.hasViewed() && item.authorId != uid{
            item.viewers[uid] = 1
            FirebaseService.addView(item.getKey())
        }
    }
    
    func nextItem() {
        if !looping {
            viewIndex += 1
        }
        shouldPlay = true
        
        setupItem()
    }
    
    func prevItem() {
        guard let item = self.item else { return }
        guard let timer = self.timer else { return }
        let remaining = timer.fireDate.timeIntervalSinceNow
        let diff = remaining / item.getLength()
        
        if diff > 0.75 {
            if viewIndex > 0 {
                viewIndex -= 1
            }
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
        shouldPlay = false
        content.image = nil
        authorOverlay.cleanUp()
        commentsView.cleanUp()
        destroyVideoPlayer()
        killTimer()
        progressBar?.resetAllProgressBars()
        progressBar?.removeFromSuperview()
        commentsRef?.removeAllObservers()
        textView.userInteractionEnabled = false
        moreButton.userInteractionEnabled = false
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    var looping = false
    
    func resumeStory() {
        looping = false
    }
    
    func pauseStory() {
        looping = true
//        killTimer()
//        self.resetVideo()
//        progressBar?.pauseActiveIndicator()
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
        if keyboardUp {
            dismissKeyboard()
        } else {
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
    
    var textView:UITextView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.0)
        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.videoContent)
        self.contentView.addSubview(self.fadeCover)
        self.contentView.addSubview(self.prevView)
        self.contentView.addSubview(self.authorOverlay)
        self.contentView.addSubview(self.viewsButton)
        
        

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
        
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .BallScaleRipple, color: UIColor.whiteColor(), padding: 1.0, speed: 1.0)
        activityView.center = self.contentView.center
        
        textView = UITextView(frame: CGRectMake(0,frame.height - 44 ,frame.width - 26, 44))
        
        textView.font = UIFont(name: "AvenirNext-Medium", size: 16.0)
        textView.textColor = UIColor.whiteColor()
        textView.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        textView.hidden = false
        textView.keyboardAppearance = .Dark
        textView.returnKeyType = .Send
        textView.scrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.text = "Send a message"
        textView.delegate = self
        textView.fitHeightToContent()
        textView.text = ""
        
        self.contentView.addSubview(self.commentsView)
        
        commentPlaceHolderLabel = UILabel(frame: CGRectMake(10,textView.frame.origin.y, textView.frame.width, textView.frame.height))
        
        commentPlaceHolderLabel.textColor = UIColor(white: 1.0, alpha: 0.5)
        commentPlaceHolderLabel.text = "Comment"
        commentPlaceHolderLabel.font = UIFont(name: "AvenirNext-Medium", size: 14.0)
        
        self.addSubview(commentPlaceHolderLabel)
        
        self.contentView.addSubview(textView)
        
        commentsView.frame = CGRectMake(0, textView.frame.origin.y - commentsView.frame.height, commentsView.frame.width, commentsView.frame.height)
        
        self.contentView.addSubview(self.moreButton)
        
        self.contentView.addSubview(activityView)
        
    }
    
    func setLoopState(looping:Bool) {
        self.looping = looping
    }
    
    var commentPlaceHolderLabel:UILabel!
    
    var keyboardUp = false
    
    func keyboardWillAppear(notification: NSNotification){

        keyboardUp = true
        looping = true
        
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            let height = self.frame.height
            let textViewFrame = self.textView.frame
            let textViewY = height - keyboardFrame.height - textViewFrame.height
            self.textView.frame = CGRectMake(0,textViewY, textViewFrame.width, textViewFrame.height)
            
            let commentLabelFrame = self.commentPlaceHolderLabel.frame
            let commentLabelY = height - keyboardFrame.height - commentLabelFrame.height
            self.commentPlaceHolderLabel.frame = CGRectMake(commentLabelFrame.origin.x,commentLabelY, commentLabelFrame.width, commentLabelFrame.height)
            
            let commentsViewStart = textViewY - self.commentsView.frame.height
            self.commentsView.frame = CGRectMake(0, commentsViewStart, self.commentsView.frame.width, self.commentsView.frame.height)
            
            let moreButtonFrame = self.moreButton.frame
            let moreButtonY = height - keyboardFrame.height - moreButtonFrame.height
            self.moreButton.frame = CGRectMake(moreButtonFrame.origin.x,moreButtonY, moreButtonFrame.width, moreButtonFrame.height)
            
            self.progressBar?.alpha = 0.0
            self.authorOverlay.alpha = 0.0
            self.commentPlaceHolderLabel.alpha = 0.0
        })
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        keyboardUp = false
        looping = false
        
        
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
            let height = self.frame.height
            let textViewFrame = self.textView.frame
            let textViewStart = height - textViewFrame.height
            self.textView.frame = CGRectMake(0,textViewStart, textViewFrame.width, textViewFrame.height)
            
            let commentLabelFrame = self.commentPlaceHolderLabel.frame
            let commentLabelY = height - commentLabelFrame.height
            self.commentPlaceHolderLabel.frame = CGRectMake(commentLabelFrame.origin.x,commentLabelY, commentLabelFrame.width, commentLabelFrame.height)
            
            let commentsViewStart = textViewStart - self.commentsView.frame.height
            self.commentsView.frame = CGRectMake(0, commentsViewStart, self.commentsView.frame.width, self.commentsView.frame.height)
            
            let moreButtonFrame = self.moreButton.frame
            self.moreButton.frame = CGRectMake(moreButtonFrame.origin.x,height - moreButtonFrame.height, moreButtonFrame.width, moreButtonFrame.height)
            
            self.progressBar?.alpha = 1.0
            self.authorOverlay.alpha = 1.0
            if !self.commentLabelShouldHide() {
                self.commentPlaceHolderLabel.alpha = 1.0
            }
            
            }, completion:  { result in
                
        })
        
    }
    
    func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func sendComment(comment:String) {
        textView.text = ""
        updateTextAndCommentViews()
        print("Send comment: \(comment)")
        if item != nil {
            FirebaseService.addComment(item!.getKey(), comment: comment)
        }
    }
    
    func commentLabelShouldHide() -> Bool {
        if textView.text.isEmpty {
            return false
        } else {
            return true
        }
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
        
        authorView.frame = CGRect(x: margin, y: margin + 8.0, width: width, height: authorView.frame.height)
        authorView.authorTappedHandler = self.authorTappedHandler
        return authorView
    }()
    
    lazy var commentsView: CommentsView = {
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        var commentsView = CommentsView(frame: CGRect(x: 0, y: height / 2, width: width, height: height * 0.35 ))
        
        return commentsView
    }()

    
    lazy var viewsButton: UIButton = {
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let button = UIButton(frame: CGRectMake(12,height - 36,40,40))
        button.titleLabel!.font = UIFont.init(name: "AvenirNext-Medium", size: 16)
        button.tintColor = UIColor.whiteColor()
        button.alpha = 0.0//0.70
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
    
    var change:CGFloat = 0
    
    func updateTextAndCommentViews() {
        let oldHeight = textView.frame.size.height
        textView.fitHeightToContent()
        change = textView.frame.height - oldHeight
        
        
        textView.center = CGPoint(x: textView.center.x, y: textView.center.y - change)
        
        self.commentsView.frame = CGRectMake(0, textView.frame.origin.y - self.commentsView.frame.height, self.commentsView.frame.width, self.commentsView.frame.height)
    }
}

extension StoryViewController: UITextViewDelegate {
    public func textViewDidChange(textView: UITextView) {
        updateTextAndCommentViews()
    }
    
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            print("Length: \(textView.text.characters.count)")
            if textView.text.characters.count > 0 {
                sendComment(textView.text)
            } else {
                //dismissKeyboard()
            }
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 140
    }
}
