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
    private static var listeningToFollowers = false
    private static var listeningToFollowing = false
    private static var listeningToResponses = false
    
    
    static func stopListeningToAll() {
        stopListeningToFriends()
        stopListeningToLocations()
        stopListeningToConversatons()
        stopListeningToFriendRequests()
        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToResponses()
    }
    
    static func startListeningToFriends() {
        if !listeningToFriends {
            listeningToFriends = true
            let uid = mainStore.state.userState.uid
            let friendsRef = ref.child("users/social/friends/\(uid)")
            
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
    
    static func stopListeningToFriends() {
        let uid = mainStore.state.userState.uid
        let friendsRef = ref.child("users/social/friends/\(uid)")
        friendsRef.removeAllObservers()
        
        listeningToFriends = false
    }
    
    static func startListeningToLocations() {
        if !listeningToLocations {
            listeningToLocations = true
            let locations = mainStore.state.locations
            
            
            for i in 0 ..< locations.count {
                let location = locations[i]
                let locationRef = ref.child("locations")
                
                locationRef.child("visitors/\(location.getKey())").observeEventType(.Value, withBlock: { snapshot in
                    if snapshot.exists() {
                        var visitors = [String]()
                        for visitor in snapshot.children {
                            visitors.append(visitor.key!!)
                        }
                        mainStore.dispatch(SetVisitorsForLocation(locationIndex: i, visitors: visitors))
                    }
                })
            }
        }
    }
    
    static func stopListeningToLocations() {
        let locations = mainStore.state.locations
        
        for location in locations {
            let locationRef = ref.child("locations")
            locationRef.child("visitors/\(location.getKey())").removeAllObservers()
            locationRef.child("uploads/\(location.getKey())").removeAllObservers()
            
        }
        listeningToLocations = false
    }
    
    static func startListeningToFriendRequests() {
        if !listeningToFriendRequests {
            listeningToFriendRequests = true
            let uid = mainStore.state.userState.uid
            let requestsInRef = ref.child("users/social/requestsIn/\(uid)")
            
            /**
             Listen for a Friend Request In Added
             */
            requestsInRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        print("Friend request in!")
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
            
            let requestsOutRef = ref.child("users/social/requestsOut/\(uid)")
            
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
    
    static func stopListeningToFriendRequests() {
        let uid = mainStore.state.userState.uid
        let requestsInRef = ref.child("users/social/requestsIn/\(uid)")
        requestsInRef.removeAllObservers()
        let requestsOutRef = ref.child("users/social/requestsOut/\(uid)")
        requestsOutRef.removeAllObservers()
        listeningToFriendRequests = false
    }
    
    static func startListeningToConversations() {
        if !listeningToConversations {
            listeningToConversations = true
            let uid = mainStore.state.userState.uid
            let conversationsRef = ref.child("users/conversations/\(uid)")
            print(conversationsRef)
            conversationsRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                print("walk")
                if snapshot.exists() {
                    let partner = snapshot.key
                    let conversationKey = snapshot.value! as! String
                    let conversation = Conversation(key: conversationKey, partner_uid: partner)
                    
                    print("\(partner) - key \(conversationKey)")
                    mainStore.dispatch(ConversationAdded(conversation: conversation))
                }
            })
        }
    }
    
    static func stopListeningToConversatons() {
        let uid = mainStore.state.userState.uid
        let conversationsRef = ref.child("users/conversations/\(uid)")
        conversationsRef.removeAllObservers()
        listeningToConversations = false
    }
    
    static func startListeningToFollowers() {
        if !listeningToFollowers {
            listeningToFollowers = true
            let current_uid = mainStore.state.userState.uid
            let followersRef = ref.child("users/social/followers/\(current_uid)")
            
            /**
             Listen for a Follower Added
             */
            followersRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        print("Friend request in!")
                        mainStore.dispatch(AddFollower(uid: snapshot.key))
                    }
                    
                }
            })
            
            
            /**
             Listen for a Follower Removed
             */
            followersRef.observeEventType(.ChildRemoved, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(RemoveFollower(uid: snapshot.key))
                    }
                }
            })
            
            
        }
    }
    
    static func startListeningToFollowing() {
        if !listeningToFollowing {
            listeningToFollowing = true
            let current_uid = mainStore.state.userState.uid
            let followingRef = ref.child("users/social/following/\(current_uid)")
            
            /**
             Listen for a Following Added
             */
            followingRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        print("Friend request in!")
                        mainStore.dispatch(AddFollowing(uid: snapshot.key))
                    }
                    
                }
            })
            
            
            /**
             Listen for a Following Removed
             */
            followingRef.observeEventType(.ChildRemoved, withBlock: { snapshot in
                if snapshot.exists() {
                    if let seen = snapshot.value! as? Bool {
                        mainStore.dispatch(RemoveFollowing(uid: snapshot.key))
                    }
                }
            })
            
            
        }
    }
    
    static func stopListeningToFollowers() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowers = false
    }
    
    static func stopListeningToFollowing() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowing = false
    }
    
    static func startListeningToResponses() {
        if !listeningToResponses {
            listeningToResponses = true
            let current_uid = mainStore.state.userState.uid
            let responsesRef = ref.child("api/responses")
            
            /**
             Listen for a Following Added
             */
            let locationUpdatesRef = responsesRef.child("location_updates/\(current_uid)")
            locationUpdatesRef.observeEventType(.Value, withBlock: { snapshot in
                if snapshot.exists() {
                    let locationsDictionary = snapshot.value! as! [String:Double]
                    LocationService.handleLocationsResponse(locationsDictionary)
                    locationUpdatesRef.removeValue()                    
                }
            })
        }
    }
    
    static func stopListeningToResponses() {
        let current_uid = mainStore.state.userState.uid
        ref.child("api/responses/location_updates/\(current_uid)").removeAllObservers()
        listeningToResponses = false
    }
    
    
    
}
