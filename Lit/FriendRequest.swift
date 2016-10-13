//
//  FriendRequest.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation


enum FriendStatus: String {
    case PENDING_INCOMING = "PENDING_INCOMING"
    case PENDING_INCOMING_SEEN = "PENDING_INCOMING_SEEN"
    case PENDING_OUTGOING = "PENDING_OUTGOING"
    case FRIENDS = "FRIENDS"
    case NOT_FRIENDS = "NOT_FRIENDS"
    case IS_CURRENT_USER = "IS_CURRENT_USER"
}


class FriendRequest {
    
    private var friend_uid:String
    
    private var status:FriendStatus
    
    init(friend_uid:String, status:FriendStatus)
    {
        self.friend_uid = friend_uid
        self.status = status
    }
    
    
    func getId() -> String {
        return friend_uid
    }
    
    func getStatus() -> FriendStatus {
        return status
    }
    
    func setStatus(status:FriendStatus) {
        self.status = status
    }
    
    
}