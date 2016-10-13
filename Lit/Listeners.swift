//
//  ListenersService.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift


class Listeners {

    private static let ref = FIRDatabase.database().reference()
    
    private static var listeningToFriends = false
    private static var listeningToFriendRequests = false
    private static var listeningToLocations = false
    private static var listeningToConversations = false
    
    static func listenToFriends() {
        if !listeningToFriends {
            listeningToFriends = true
            
            let friendsRef = ref.child("users_public/\(mainStore.state.userState.uid)/friends")
            
            /**
             Listen for a Friend Added
             */
            friendsRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    mainStore.dispatch(AddFriend(uid: snapshot.key))
                }
            })
            
            /**
             Listen for a Friend Removed
             */
            friendsRef.observeEventType(.ChildRemoved, withBlock: { snapshot in
                if snapshot.exists() {
                    mainStore.dispatch(RemoveFriend(uid: snapshot.key))
                }
            })
        }
    }
    
    static func listenToLocations() {
        if !listeningToLocations {
            listeningToLocations = true
            let city = mainStore.state.userState.activeCity!.getKey()
            let locations = mainStore.state.locations
            
            
            for i in 0 ..< locations.count {
                let location = locations[i]
                let locationRef = ref.child("locations/\(city)/\(location.getKey())")
                
                locationRef.child("visitors").observeEventType(.ChildAdded, withBlock: { snapshot in
                    if snapshot.exists() {
                        mainStore.dispatch(AddVisitorToLocation(locationIndex: i, uid: snapshot.key))
                    }
                })
                
                locationRef.child("visitors").observeEventType(.ChildRemoved, withBlock: { snapshot in
                    if snapshot.exists() {
                        mainStore.dispatch(RemoveVisitorFromLocation(locationIndex: i, uid: snapshot.key))
                    }
                })
                
                
                locationRef.child("uploads").observeEventType(.ChildAdded, withBlock: { snapshot in
                    if snapshot.exists() {
                        mainStore.dispatch(AddPostToLocation(locationIndex: i, key: snapshot.key))
                    }
                })
                
                locationRef.child("uploads").observeEventType(.ChildRemoved, withBlock: { snapshot in
                    if snapshot.exists() {
                        mainStore.dispatch(RemovePostFromLocation(locationIndex: i, key: snapshot.key))
                    }
                })
            }
            
        }
    }
    
    static func listenToFriendRequests() {
        if !listeningToFriendRequests {
            listeningToFriendRequests = true
            
            let requestsInRef = ref.child("users_public/\(mainStore.state.userState.uid)/friendRequestsIn")
            
            /**
             Listen for a Friend Request In Added
             */
            requestsInRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(AddFriendRequestIn(uid: snapshot.key, seen: seen))
                    }

                }
            })
            
            /**
             Listen for a Friend Request In Changed
             */
            requestsInRef.observeEventType(.ChildChanged, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        if seen {
                            mainStore.dispatch(SeenFriendRequestIn(uid: snapshot.key))
                        }
                    }
                    
                }
            })
            
            /**
             Listen for a Friend Request In Removed
             */
            requestsInRef.observeEventType(.ChildRemoved, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(RemoveFriendRequestIn(uid: snapshot.key, seen: seen))
                    }
                    
                }
            })
            
            let requestsOutRef = ref.child("users_public/\(mainStore.state.userState.uid)/friendRequestsOut")
            
            /**
             Listen for a Friend Request Out Added
             */
            requestsOutRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(AddFriendRequestOut(uid: snapshot.key, seen: seen))
                    }
                    
                }
            })
            
            /**
             Listen for a Friend Request Out Removed
             */
            requestsOutRef.observeEventType(.ChildRemoved, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(RemoveFriendRequestOut(uid: snapshot.key, seen: seen))
                    }
                    
                }
            })
        }
    }
    
    static func listenToConversations() {
        if !listeningToConversations {
            listeningToConversations = true
            let uid = mainStore.state.userState.uid
            let conversationsRef = ref.child("users_public/\(uid)/conversations")
            
            conversationsRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            
                if snapshot.exists() {
                    let partner = snapshot.key
                    let conversationKey = snapshot.value! as! String
                    let conversation = Conversation(key: conversationKey, partner_uid: partner)
                    mainStore.dispatch(ConversationAdded(conversation: conversation))
                }
            })
        }
    }
}
