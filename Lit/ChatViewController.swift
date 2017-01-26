//
//  ChatViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import ReSwift
import Firebase


class ChatTitleView: UIView {
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    func setUser(uid:String) {
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.clipsToBounds = true
        FirebaseService.getUser(uid, completionHandler: { user in
            if user != nil {
                self.usernameLabel.text = user!.getDisplayName()
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    self.profileImage.image = image
                })
            }
        })
        
    }
}

class ChatViewController: JSQMessagesViewController, GetUserProtocol {
    

    var isEmpty = false
    var refreshControl: UIRefreshControl!

    var containerDelegate:ContainerViewController?
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(white: 0.3, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(accentColor)
    var messages:[JSQMessage]!
    
    var settingUp = true
    
    var conversation:Conversation!
    var partner:User!
    {
        didSet {
            
            self.title = partner.getDisplayName()
            if containerDelegate != nil {
                containerDelegate?.title = partner.getDisplayName()
            }

        }
    }
    
    var partnerImage:UIImage?
    

    func userLoaded(user: User) {
        partner = user
       
    }

    var activityIndicator:UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        messages = [JSQMessage]()
        // Do any additional setup after loading the view, typically from a nib.
        self.collectionView?.backgroundColor = UIColor.blackColor()
        self.navigationController?.navigationBar.backItem?.backBarButtonItem?.title = " "
        
        self.inputToolbar.barTintColor = UIColor.blackColor()
        self.inputToolbar.contentView.leftBarButtonItemWidth = 0
        self.inputToolbar.contentView.textView.keyboardAppearance = .Dark
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        self.inputToolbar.contentView.textView.textColor = UIColor.whiteColor()
        self.inputToolbar.contentView.textView.layer.borderColor = UIColor(white: 0.10, alpha: 1.0).CGColor
        self.inputToolbar.contentView.textView.layer.borderWidth = 1.0
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        collectionView?.collectionViewLayout.springinessEnabled = true
        
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.activityIndicatorViewStyle = .White
        activityIndicator.center = CGPointMake(UIScreen.mainScreen().bounds.size.width / 2, UIScreen.mainScreen().bounds.size.height / 2 - 50)
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()


        conversation.delegate = self
        if let user = conversation.getPartner() {
            partner = user
        }
        
        downloadRef = FirebaseService.ref.child("conversations/\(conversation.getKey())/messages")
        
        downloadRef?.queryOrderedByKey().queryLimitedToLast(1).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if !snapshot.exists() {
                self.stopActivityIndicator()
            }
        })

        self.setup()
        self.downloadMessages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appMovedToBackground), name:UIApplicationDidEnterBackgroundNotification, object: nil)

    }
    
    func startActivityIndicator() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.settingUp {
               self.activityIndicator.startAnimating()
            }
        })
    }
    
    
    func stopActivityIndicator() {
        if settingUp {
            settingUp = false
            print("Swtich activity indicator")
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                self.refreshControl = UIRefreshControl()
                self.refreshControl.tintColor = UIColor.whiteColor()
                self.refreshControl.addTarget(self, action: #selector(self.handleRefresh), forControlEvents: .ValueChanged)
                self.collectionView?.addSubview(self.refreshControl)

            })
        }
    }
    
    func handleRefresh() {
        let oldestLoadedMessage = messages[0]
        let date = oldestLoadedMessage.date
        let endTimestamp = date.timeIntervalSince1970 * 1000
        
        limit += 16
        downloadRef?.queryOrderedByChild("timestamp").queryLimitedToLast(limit).queryEndingAtValue(endTimestamp).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                var messageBatch = [JSQMessage]()
                for message in snapshot.children {
                    let messageSnap = message as! FIRDataSnapshot
                    let senderId = messageSnap.value!["senderId"] as! String
                    let text     = messageSnap.value!["text"] as! String
                    let timestamp     = messageSnap.value!["timestamp"] as! Double
                    
                    if timestamp != endTimestamp {
                        let date = NSDate(timeIntervalSince1970: timestamp/1000)
                        let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                        messageBatch.append(message)
                        
                    }
                    
                }
                if messageBatch.count > 0 {
                    self.messages.insertContentsOf(messageBatch, at: 0)
                    self.reloadMessagesView()
                    self.refreshControl.endRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                    self.refreshControl.enabled = false
                    self.refreshControl.removeFromSuperview()
                }
            } else {
                self.refreshControl.endRefreshing()
                self.refreshControl.enabled = false
                self.refreshControl.removeFromSuperview()
            }
        })
    }
    
    func appMovedToBackground() {
        downloadRef?.removeAllObservers()
        conversation.listenToConversation()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        downloadRef?.removeAllObservers()
        conversation.listenToConversation()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
        //set seen timestamp
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("conversations/\(conversation.getKey())/\(uid)")
        ref.updateChildValues(["seen": [".sv":"timestamp"]])
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
        
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        self.messages.removeAtIndex(indexPath.row)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return nil
        default:
            if partnerImage != nil {
                let image = JSQMessagesAvatarImageFactory.avatarImageWithImage(partnerImage!, diameter: 48)
                return image
            }
            
            return nil
        }

    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            cell.textView?.textColor = UIColor(white: 0.96, alpha: 1.0)
        default:
            cell.textView?.textColor = UIColor(white: 0.96, alpha: 1.0)
        }
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {

        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(currentItem.date)
        }
        
        
        if indexPath.item > 0 {
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSinceDate(prevItem.date)
            
            if gap > 1800 {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(currentItem.date)
            }
        } else {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(currentItem.date)
        }

        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        if indexPath.item > 0 {
            let currentItem = self.messages[indexPath.item]
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSinceDate(prevItem.date)
            
            if gap > 1800 {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            
            if prevItem.senderId != currentItem.senderId {
                return 1.0
            }
        }  else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let prevItem = indexPath.item - 1
        
        if prevItem >= 0 {
            let prevMessage = messages[prevItem]
            if prevMessage.isMediaMessage {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let prevItem = indexPath.item - 1
        
        if prevItem >= 0 {
            let prevMessage = messages[prevItem]
            if prevMessage.isMediaMessage {
                return NSAttributedString(string: "            Temporary message.", attributes: nil)
            }
        }
        return NSAttributedString(string: "")
    }
    
    var loadingNextBatch = false
    var downloadRef:FIRDatabaseReference?
    
    var lastTimeStamp:Double?
    var limit:UInt = 16

}

//MARK - Setup
extension ChatViewController {
    
    func setup() {
        self.senderId = mainStore.state.userState.uid
        self.senderDisplayName = ""
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        SocialService.sendMessage(conversation, message: text, uploadKey: nil, completionHandler: nil)
        
        self.finishSendingMessageAnimated(true)
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
    }
    
    
    

    func downloadMessages() {
        
        self.messages = []

        downloadRef?.queryOrderedByChild("timestamp").queryLimitedToLast(limit).observeEventType(.ChildAdded, withBlock: { snapshot in
                let senderId = snapshot.value!["senderId"] as! String
                let text     = snapshot.value!["text"] as! String
                let timestamp     = snapshot.value!["timestamp"] as! Double
                
                let date = NSDate(timeIntervalSince1970: timestamp/1000)
            
                if let uploadKey = snapshot.value!["upload"] as? String {
                    let mediaItem = AsyncPhotoMediaItem(withURL: uploadKey)
                    let mediaMessage = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, media: mediaItem)
                    let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                    self.messages.append(mediaMessage)
                    self.messages.append(message)
                    self.reloadMessagesView()
                    self.stopActivityIndicator()
                    self.finishReceivingMessageAnimated(true)
                    SocialService.deleteMessage(self.conversation, messageKey: snapshot.key)
                    
                } else {
                    let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                    self.messages.append(message)
                    self.reloadMessagesView()
                    self.stopActivityIndicator()
                    self.finishReceivingMessageAnimated(true)
                }
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    

}

class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: String) {
        super.init()

        let size = UIScreen.mainScreen().bounds
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRectMake(0, 0, size.width * 0.5, size.height * 0.35)
        asyncImageView.contentMode = .ScaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 5
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGrayColor()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.viewWithActivityIndicator()
        activityIndicator?.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator!)
        
        
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            if image != nil {
                self.asyncImageView.image = image!
                activityIndicator.removeFromSuperview()
            }
        })
    }
    
    override func mediaView() -> UIView! {
        return asyncImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}