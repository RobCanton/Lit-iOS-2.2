//
//  Conversation.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import Foundation
import JSQMessagesViewController

protocol GetUserProtocol {
    func userLoaded(user:User)
}

class Conversation {
    
    private var key:String
    private var partner_uid:String
    private var partner:User?
    
    private var conversationRef:FIRDatabaseReference?
    
    var lastMessage:JSQMessage?
    var seenDate:NSDate?
    
    var seen:Bool = true
    
    var delegate:GetUserProtocol?
    
    init(key:String, partner_uid:String)
    {
        self.key         = key
        self.partner_uid = partner_uid
        retrieveUser()
        listenToConversation()
    }
    
    func getKey() -> String {
        return key
    }
    
    func getPartnerId() -> String {
        return partner_uid
    }
    
    func getPartner() -> User? {
        return partner
    }
    

    func retrieveUser() {
        FirebaseService.getUser(partner_uid, completionHandler: { _user in
            if let user = _user {
                self.partner = user
                self.delegate?.userLoaded(self.partner!)
            }
        })
    }
    
    func listenToConversation() {
        conversationRef = FirebaseService.ref.child("conversations/\(key)")
        conversationRef!.child("messages").queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { snapshot in
            if snapshot.exists() {
                let senderId = snapshot.value!["senderId"] as! String
                let text     = snapshot.value!["text"] as! String
                let timestamp     = snapshot.value!["timestamp"] as! Double
                let date = NSDate(timeIntervalSince1970: timestamp/1000)
                let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: date, text: text)
                mainStore.dispatch(NewMessageInConversation(message: message, conversationKey: self.key))
            }
        })
        
        conversationRef!.child(mainStore.state.userState.uid).observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                let seenTimestamp = snapshot.value!["seen"] as! Double
                let seenDate = NSDate(timeIntervalSince1970: seenTimestamp/1000)
                mainStore.dispatch(SeenConversation(seenDate: seenDate, conversationKey: self.key))
            }
        })
    }
    
    func stopListening() {
        conversationRef?.removeAllObservers()
    }

}