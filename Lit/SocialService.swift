//
//  SocialService.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift

class SocialService {
    

    
    static let ref = FIRDatabase.database().reference()

    static func followUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = FirebaseService.ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.setValue(false)
        
        let currentUserRef = FirebaseService.ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.setValue(false, withCompletionBlock: {
            error, ref in
        })
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = FirebaseService.ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.removeValue()
        
        let currentUserRef = FirebaseService.ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
    }
}