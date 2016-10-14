//
//  MessagesViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class MessagesViewController: UITableViewController, StoreSubscriber {
    
    let cellIdentifier = "conversationCell"
    
    var conversations = [Conversation]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        conversations = state.conversations
        tableView.reloadData()
        
        if state.messageUser != "" {
            openConversation(state.messageUser)
        }
    }
    
    func openConversation(recipient_uid:String) {
        let uid = mainStore.state.userState.uid
        mainStore.dispatch(ConversationOpened())
        
        // if new conversation
        
        if let conversation = checkForExistingConversation(recipient_uid) {
            presentConversation(conversation)
        } else {
            
        }
        
//        if true {
//            let ref = FirebaseService.ref.child("conversations").childByAutoId()
//            let conversationKey = ref.key
//            
//            let conversationData = [
//                "user_A": uid,
//                "user_B": recipient_uid
//                ]
//            ref.setValue(conversationData, withCompletionBlock: { error, ref in
//                let currentUserRef = FirebaseService.ref.child("users_public/\(uid)/conversations")
//                currentUserRef.child(recipient_uid).setValue(conversationKey)
//                
//                let recipientUserRef = FirebaseService.ref.child("users_public/\(recipient_uid)/conversations")
//                recipientUserRef.child(uid).setValue(conversationKey)
//            })
//            
//        }
////        conversations.append(recipient_uid)
////        tableView.reloadData()
        
        
    }
    
    func checkForExistingConversation(partner_uid:String) -> Conversation? {
        for conversation in conversations {
            if conversation.getPartnerId() == partner_uid {
                return conversation
            }
        }
        return nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        
        conversations = mainStore.state.conversations
        tableView.reloadData()
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ConversationViewCell
        cell.conversation = conversations[indexPath.item]
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        presentConversation(conversations[indexPath.item])
    }
    
    
    func presentConversation(conversation:Conversation) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        controller.conversation = conversation
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    

    
}
