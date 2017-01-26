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
    
    func getConversations() {
        conversations = getNonEmptyConversations()
        conversations.sortInPlace({ $0 > $1 })
        tableView.reloadData()
    }
    
    func newState(state: AppState) {
        
        getConversations()

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
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView.tableFooterView = UIView()
        
        getConversations()
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
        FirebaseService.getUser(conversation.getPartnerId(), completionHandler: { user in
            if user != nil {
                
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
                    controller.conversation = conversation
                    controller.partnerImage = image
                    self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
                    self.navigationController?.pushViewController(controller, animated: true)
                })
            }
        })
    }
    
    // MARK: UITableViewDelegate Methods
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            handleDelete(indexPath)
        }
    }
    
    func handleDelete(indexPath:NSIndexPath) -> Void {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ConversationViewCell
        let name = cell.usernameLabel.text!
        
        let actionSheet = UIAlertController(title: "Delete conversation with \(name)?", message: "Further messages from \(name) will be muted until you reply.", preferredStyle: .Alert)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        
        actionSheet.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive)
        { action -> Void in
            let partner = self.conversations[indexPath.row].getPartnerId()
            let uid = mainStore.state.userState.uid
            
            let userRef = FirebaseService.ref.child("users/conversations/\(uid)/\(partner)")
            
            userRef.removeValueWithCompletionBlock({ error, ref in
                mainStore.dispatch(RemoveConversation(index: indexPath.row))
            })
        }
        actionSheet.addAction(saveActionButton)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)

    }

    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    func removeConversation(index:Int) {
//        let alert = UIAlertView(title: "Delete conversation", message: <#T##String#>, delegate: <#T##UIAlertViewDelegate?#>, cancelButtonTitle: <#T##String?#>, otherButtonTitles: <#T##String#>, <#T##moreButtonTitles: String...##String#>)
//        let conversation = conversations[index]
//        let uid = mainStore.state.userState.uid
//        let ref = FirebaseService.ref.child("conversations/\(conversation.getKey())/\(uid)")
//        ref.updateChildValues(["removed":true])
//        mainStore.dispatch(RemoveConversation(index: index))
    }
    
    

    
}
