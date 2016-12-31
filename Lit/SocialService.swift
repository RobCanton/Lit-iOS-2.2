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
        
        let followRequestRef = FirebaseService.ref.child("api/requests/social").childByAutoId()
        followRequestRef.setValue([
                "type": "FOLLOW",
                "sender": current_uid,
                "recipient": uid
        ])
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = FirebaseService.ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.removeValue()
        
        let currentUserRef = FirebaseService.ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
        
        let followRequestRef = FirebaseService.ref.child("api/requests/social").childByAutoId()
        followRequestRef.setValue([
            "type": "UNFOLLOW",
            "sender": current_uid,
            "recipient": uid
            ])
    }
    
    static func listenToFollowers(uid:String, completionHandler:(followers:[String])->()) {
        let followersRef = FirebaseService.ref.child("users/social/followers/\(uid)")
        followersRef.observeEventType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
            }
            completionHandler(followers: _users)
        })
    }
    
    
    
    static func listenToFollowing(uid:String, completionHandler:(following:[String])->()) {
        let followingRef = FirebaseService.ref.child("users/social/following/\(uid)")
        followingRef.observeEventType(.Value, withBlock: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                for user in snapshot.children {
                    let uid = user.key!!
                    _users.append(uid)
                }
            }
            completionHandler(following: _users)
        })
    }
    
    static func stopListeningToFollowers(uid:String) {
        if uid != mainStore.state.userState.uid {
           FirebaseService.ref.child("users/social/followers/\(uid)").removeAllObservers()
        }
    }
    
    static func stopListeningToFollowing(uid:String) {
        if uid != mainStore.state.userState.uid {
            FirebaseService.ref.child("users/social/following/\(uid)").removeAllObservers()
        }
    }
}