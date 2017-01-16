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
        
        
//        let titleView = UINib(nibName: "ChatTitleView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ChatTitleView
//        
//        self.navigationItem.titleView = titleView
//        titleView.setUser(conversation.getPartnerId())
        
        conversation.delegate = self
        if let user = conversation.getPartner() {
            partner = user
        }
        
        downloadRef = FirebaseService.ref.child("conversations/\(conversation.getKey())/messages")
        self.setup()
        self.downloadMessages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appMovedToBackground), name:UIApplicationDidEnterBackgroundNotification, object: nil)
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
    
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {

        let currentItem = self.messages[indexPath.item]
        
        if indexPath.item == 0 && messages.count > 8 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(currentItem.date)
        }
        
        
        if indexPath.item > 0 {
            let prevItem    = self.messages[indexPath.item-1]
            
            let gap = currentItem.date.timeIntervalSinceDate(prevItem.date)
            
            if gap > 3600 {
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
            
            if gap > 3600 {
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
    
    var limit:UInt = 10
    var loadingNextBatch = false
    var downloadRef:FIRDatabaseReference?

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

        downloadRef?.observeEventType(.ChildAdded, withBlock: { snapshot in
                let senderId = snapshot.value!["senderId"] as! String
                let text     = snapshot.value!["text"] as! String
                let timestamp     = snapshot.value!["timestamp"] as! Double
                
                let date = NSDate(timeIntervalSince1970: timestamp/1000)
                let message = JSQMessage(senderId: senderId, senderDisplayName: "Rob", date: date, text: text)
                self.messages.append(message)
                self.reloadMessagesView()
                self.finishReceivingMessageAnimated(true)
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    

}