//
//  ConversationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import JSQMessagesViewController

func getNonEmptyConversations() -> [Conversation] {
    var activeConvos = [Conversation]()
    for conversation in mainStore.state.conversations {
        if conversation.lastMessage != nil {
            activeConvos.append(conversation)
        }
    }
    return activeConvos
}

func checkForExistingConversation(partner_uid:String) -> Conversation? {
    print("Looking for conversation")
    for conversation in mainStore.state.conversations {
        print(conversation.getPartnerId())
        if conversation.getPartnerId() == partner_uid {
            return conversation
        }
    }
    return nil
}

func findConversation(key:String) -> Conversation? {
    for conversation in mainStore.state.conversations {
        if conversation.getKey() == key {
            return conversation
        }
    }
    return nil
}

func userHasSeenMessage(seen:NSDate?, message:JSQMessage?) -> Bool{
    if seen != nil && message != nil {
        let diff = seen!.timeIntervalSinceDate(message!.date)
        if diff < 0 {
            return false
        }
    }
    else if message != nil {
        return false
    }
    return true
}

func ConversationsReducer(action: Action, state:[Conversation]?) -> [Conversation] {
    var state = state ?? [Conversation]()
    switch action {
    case _ as ConversationAdded:
        let a = action as! ConversationAdded
        print("CONVERSATION ADDED")
        state.append(a.conversation)
        break
    case _ as NewMessageInConversation:
        let a = action as! NewMessageInConversation
        if let conversation = findConversation(a.conversationKey) {
            conversation.lastMessage = a.message
            conversation.seen = userHasSeenMessage(conversation.seenDate, message: conversation.lastMessage)
        }
        break
    case _ as SeenConversation:
        let a = action as! SeenConversation
        if let conversation = findConversation(a.conversationKey) {
            conversation.seenDate = a.seenDate
            conversation.seen = userHasSeenMessage(conversation.seenDate, message: conversation.lastMessage)
        }
        break
    case _ as ClearConversations:
        state = [Conversation]()
        break
    default:
        break
    }
    return state
}


struct OpenConversation: Action {
    let uid: String
}

struct ConversationOpened: Action {
}

struct ConversationAdded: Action {
    let conversation:Conversation
}

struct NewMessageInConversation: Action {
    let message:JSQMessage
    let conversationKey:String
}

struct SeenConversation: Action {
    let seenDate:NSDate
    let conversationKey:String
}

/* Destructive Actions */

struct ClearConversations: Action {}
