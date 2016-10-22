//
//  FirebaseService.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import IngeoSDK
import AVFoundation

class FirebaseService {
    static let ref = FIRDatabase.database().reference()
    // Get a reference to the storage service, using the default Firebase App
    static let storage = FIRStorage.storage()
    static let storageRef = storage.referenceForURL("gs://lit-data.appspot.com")

    static func signOut() {
        try! FIRAuth.auth()!.signOut()
    }
    
    
    static func getUser(uid:String, completionHandler: (user:User?)->()) {
        ref.child("users/profile/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var user:User?
            if snapshot.exists() {
                let displayName      = snapshot.value!["username"] as! String
                let imageUrl         = snapshot.value!["smallProfilePicURL"] as! String
                let largeImageUrl    = snapshot.value!["largeProfilePicURL"] as! String
                let numFriends       = snapshot.value!["numFriends"] as! Int
                
//                var friends = [String:Bool]()
//                if snapshot.hasChild("friends") {
//                    friends = snapshot.value!["friends"] as! [String:Bool]
//                    print("Friends: \(friends)")
//                }
                user = User(uid: uid, displayName: displayName, imageUrl: imageUrl, largeImageUrl: largeImageUrl, numFriends: numFriends)
            }

            completionHandler(user: user)
            
        })
    }
    

    internal static func sendImage(image:UIImage) -> FIRStorageUploadTask? {
        // Data in memory
        let city = mainStore.state.userState.activeCity!
        let activeLocationKey = mainStore.state.userState.activeLocationKey
        
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key

        if let data = UIImageJPEGRepresentation(image, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = storageRef.child("user_uploads/\(postKey))").putData(data, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    let obj = [
                        "author": mainStore.state.userState.uid,
                        "location": activeLocationKey,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 4,
                        "likes": 0

                    ]
                    dataRef.child("meta").setValue(obj, withCompletionBlock: { error, _ in
                        if error == nil {
                            let locationRef = ref.child("locations/\(city.getKey())/\(activeLocationKey)/uploads/\(postKey)")
                            locationRef.setValue(true)
                            let userRef = ref.child("users/uploads/\(mainStore.state.userState.uid)/\(postKey)")
                            userRef.setValue(true)
                        }
                    })

                }
            }
            return uploadTask
            
        }
        
        return nil
    }
    
    internal static func uploadVideo(url:NSURL) -> FIRStorageUploadTask? {
        
        let city = mainStore.state.userState.activeCity!
        let activeLocationKey = mainStore.state.userState.activeLocationKey
        
        let saveRef = ref.child("/uploads/\(city.getKey())/\(activeLocationKey)").childByAutoId()
        let metadata = FIRStorageMetadata()
        let contentTypeStr = "video/mp4"
        let playerItem = AVAsset(URL: url)
        let length = CMTimeGetSeconds(playerItem.duration)
        metadata.contentType = contentTypeStr
        
        let data = NSData(contentsOfURL: url)
        
        // Upload file and metadata to the object 'images/mountains.jpg'
        let uploadTask = storageRef.child("user_uploads/\(saveRef.key))").putData(data!, metadata: metadata) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
                saveRef.removeValue()
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                saveRef.setValue([
                    "author": mainStore.state.userState.uid,
                    "url": downloadURL!.absoluteString,
                    "contentType": contentTypeStr,
                    "dateCreated": [".sv": "timestamp"],
                    "length": length,
                    "likes": 0
                    ])
            }
        }
        
        return uploadTask
    }
    
    static func deletePost(postItem:StoryItem, completionHandler:()->()) {
        let postKey = postItem.getKey()
        let uid = mainStore.state.userState.uid
        let location = postItem.getLocationKey()
        
        let locationRef = ref.child("locations/toronto/\(location)/uploads/\(postKey)")
        let userRef = ref.child("users/uploads/\(uid)/\(postKey)")
        let postRef = ref.child("uploads/\(postKey)")
        locationRef.removeValueWithCompletionBlock({ error, ref in
            userRef.removeValueWithCompletionBlock({ error, ref in
                postRef.updateChildValues(["delete":true])
                completionHandler()
            })
        })
    }
    
    static func downloadStory(postKeys:[String], completionHandler: (story:[StoryItem])->()) {
        var story = [StoryItem]()
        var loadedCount = 0
        for postKey in postKeys {
            let postRef = FirebaseService.ref.child("uploads/\(postKey)/meta")
            
            postRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                if snapshot.exists() {
                    let key = postKey
                    let authorId = snapshot.value!["author"] as! String
                    let locationKey = snapshot.value!["location"] as! String
                    let downloadUrl = snapshot.value!["url"] as! String
                    let contentTypeStr = snapshot.value!["contentType"] as! String
                    var contentType = ContentType.Invalid
                    if contentTypeStr == "image/jpg" {
                        contentType = .Image
                    } else if contentTypeStr == "video/mp4" {
                        contentType = .Video
                    }
                    
                    let dateCreated = snapshot.value!["dateCreated"] as! Double
                    let length = snapshot.value!["length"] as! Double
                    
                    var likes = 0
                    if snapshot.hasChild("likes") {
                        likes = snapshot.value!["likes"] as! Int
                    }
                    
                    
                    let storyItem = StoryItem(key: key, authorId: authorId,locationKey: locationKey, downloadUrl: downloadUrl, contentType: contentType, dateCreated: dateCreated, length: length, likes: likes)
                    story.append(storyItem)
                }
                
                loadedCount += 1
                if loadedCount >= postKeys.count {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(story: story)
                    })
                }
            })
        }
    }
    
    
    static func compressVideo(inputURL: NSURL, outputURL: NSURL, handler:(session: AVAssetExportSession)-> Void) {
        let urlAsset = AVURLAsset(URL: inputURL, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileTypeMPEG4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronouslyWithCompletionHandler { () -> Void in
                handler(session: exportSession)
            }
        }
    }
    
    static func checkFriendStatus(friend_uid:String) -> FriendStatus {
        
        if friend_uid == mainStore.state.userState.uid {
            return FriendStatus.IS_CURRENT_USER
        }
        
        let friends = mainStore.state.friends
        if friends.contains(friend_uid) {
            return FriendStatus.FRIENDS
        }
        
        let requests = mainStore.state.friendRequestsIn
        if let _ = requests[friend_uid] {
            return FriendStatus.PENDING_INCOMING
        }
        
        let requestsOut = mainStore.state.friendRequestsOut
        if let _ = requestsOut[friend_uid] {
            return FriendStatus.PENDING_OUTGOING
        }
        
        return FriendStatus.NOT_FRIENDS
        
    }
    
    
    static func sendFriendRequest(friend_uid:String, completionHandler:(success:Bool)->()) {
        
        let uid = mainStore.state.userState.uid
        let userRef = FirebaseService.ref.child("users/social/requestsOut/\(uid)/\(friend_uid)")
        userRef.setValue(false)
        let friendRef = FirebaseService.ref.child("users/social/requestsIn/\(friend_uid)/\(uid)")
        friendRef.setValue(false, withCompletionBlock: {
            error, ref in
            
            if error != nil {
                completionHandler(success: false)
            } else {
                completionHandler(success: true)
            }
        })
    }
    
    static func acceptFriendRequest(friend_uid:String) {
        let uid = mainStore.state.userState.uid
        ref.child("users/social/friends/\(uid)/\(friend_uid)").setValue(true)
        ref.child("users/social/friends/\(friend_uid)/\(uid)").setValue(true)
        ref.child("users/social/requestsOut/\(friend_uid)/\(uid)").removeValue()
        ref.child("users/social/requestsIn/\(uid)/\(friend_uid)").removeValue()
        incrementUserFriends(uid)
        incrementUserFriends(friend_uid)
    }
    
    static func incrementUserFriends(uid:String) {
        let userRef = ref.child("users/profile/\(uid)")
        userRef.child("numFriends").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var numFriends = currentData.value as? Int {
                
                numFriends += 1
                currentData.value = numFriends
                
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    

}
