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
    

    var refreshControl: UIRefreshControl!

    var containerDelegate:ContainerViewController?
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.darkGrayColor())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(accentColor)
    var messages:[JSQMessage]!
    
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
        //collectionView?.collectionViewLayout.
        
        conversation.delegate = self
        if let user = conversation.getPartner() {
            partner = user
        }
        
        downloadRef = FirebaseService.ref.child("conversations/\(conversation.getKey())/messages")
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appMovedToBackground), name:UIApplicationDidEnterBackgroundNotification, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: #selector(handleRefresh), forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        
        FirebaseService.getUser(conversation.getPartnerId(), completionHandler: { user in
            if user != nil {
                self.partner = user!
                
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    self.partnerImage = image
                    self.setup()
                    self.downloadMessages()
                })
            }
        })
       
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        downloadRef?.removeAllObservers()
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
        cell.textView.textColor = UIColor.whiteColor()
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
        
        let messageRef = FirebaseService.ref.child("conversations/\(conversation.getKey())/messages").childByAutoId()
            
        messageRef.setValue([
                "senderId": self.senderId,
                "recipientId": self.conversation.getPartnerId(),
                "text": text,
                "timestamp": [".sv":"timestamp"]
                ])
        
        let ref = FirebaseService.ref.child("api/requests/message").childByAutoId()
        ref.setValue([
                "sender": self.senderId,
                "conversation": conversation.getKey(),
                "messageID": messageRef.key,
        ])
        
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
                let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                self.messages.append(message)
                self.reloadMessagesView()
                self.finishReceivingMessageAnimated(true)
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    

}