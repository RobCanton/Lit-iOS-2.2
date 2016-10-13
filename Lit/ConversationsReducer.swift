//
//  ConversationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift


func ConversationsReducer(action: Action, state:[Conversation]?) -> [Conversation] {
    var state = state ?? [Conversation]()
    
    switch action {
    case _ as ConversationAdded:
        let a = action as! ConversationAdded
        state.append(a.conversation)
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

