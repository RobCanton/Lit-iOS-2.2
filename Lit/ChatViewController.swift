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


class ChatViewController: JSQMessagesViewController, GetUserProtocol {
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.grayColor())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(accentColor)
    var messages = [JSQMessage]()
    
    var conversation:Conversation!
    var partner:User!
    {
        didSet {
            self.title = partner.getDisplayName()
        }
    }
    
    func userLoaded(user: User) {
        partner = user
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.collectionView?.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        self.navigationController?.navigationBar.backItem?.backBarButtonItem?.title = " "
        
        conversation.delegate = self
        if let user = conversation.getPartner() {
            partner = user
        }
        
        self.setup()
        self.downloadMessages()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    
    
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
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
        return nil
    }
    
    
}

//MARK - Setup
extension ChatViewController {
    
    func setup() {
        self.senderId = mainStore.state.userState.uid
        self.senderDisplayName = ""
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        FirebaseService.ref.child("conversations/\(conversation.getKey())/messages").childByAutoId()
            .setValue([
                "senderId": self.senderId,
                "text": text,
                "timestamp": [".sv":"timestamp"]
                ])
        
        self.finishSendingMessageAnimated(true)
        
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
    }
    
    
    
    func downloadMessages() {
        FirebaseService.ref.child("conversations/\(conversation.getKey())/messages").observeEventType(.ChildAdded, withBlock: { snapshot in
                let senderId = snapshot.value!["senderId"] as! String
                let text     = snapshot.value!["text"] as! String
                let timestamp     = snapshot.value!["timestamp"] as! Double
                
                let date = NSDate(timeIntervalSince1970: timestamp)
                let message = JSQMessage(senderId: senderId, senderDisplayName: "Rob", date: date, text: text)
                self.messages.append(message)
                self.reloadMessagesView()
                self.finishSendingMessageAnimated(true)
        })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
}