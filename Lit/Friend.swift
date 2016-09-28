//
//  Friend.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation

//
//  FriendRequest.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//


class Friend : Comparable {
    
    private var friend_uid:String
    
    
    init(friend_uid:String)
    {
        self.friend_uid = friend_uid
    }
    
    
    func getId() -> String {
        return friend_uid
    }
}

func < (lhs: Friend, rhs: Friend) -> Bool {
    return lhs.friend_uid < rhs.friend_uid
}

func == (lhs: Friend, rhs: Friend) -> Bool {
    return lhs.friend_uid == rhs.friend_uid
}