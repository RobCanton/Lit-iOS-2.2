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
import FBSDKCoreKit
import FBSDKLoginKit
import BRYXBanner
import Whisper



class FirebaseService {
    
    static let dataCache = NSCache()
    
    static let ref = FIRDatabase.database().reference()
    // Get a reference to the storage service, using the default Firebase App
    static let storage = FIRStorage.storage()
    static let storageRef = storage.referenceForURL("gs://lit-data.appspot.com")

    static func logout() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        logoutOfFirebase()
    }
    
    static func logoutOfFirebase() {
        try! FIRAuth.auth()!.signOut()
        GPSService.sharedInstance.stopUpdatingLocation()
        LocationService.shouldCalculateNearbyArea = true
        Listeners.stopListeningToAll()
        mainStore.dispatch(ClearConversations())
        mainStore.dispatch(ClearCities())
        mainStore.dispatch(ClearLocations())
        mainStore.dispatch(ClearFriendRequestsIn())
        mainStore.dispatch(ClearFriendRequestsOut())
        mainStore.dispatch(ClearFriends())
        mainStore.dispatch(ClearSocialState())
        mainStore.dispatch(UserIsUnauthenticated())
    }
    
    static func login(user:User) {
        mainStore.dispatch(UserIsAuthenticated(user: user))
        Listeners.startListeningToFriends()
        Listeners.startListeningToFriendRequests()
        Listeners.startListeningToConversations()
        Listeners.startListeningToFollowers()
        Listeners.startListeningToFollowing()
        Listeners.startListeningToResponses()
        
        sendFCMToken()
    }
    
    
    static func getUser(uid:String, completionHandler: (user:User?)->()) {
        
        if let cachedUser = dataCache.objectForKey("user-\(uid)") as? User {
            completionHandler(user: cachedUser)
            
        } else {
            ref.child("users/profile/basic/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                var user:User?
                if snapshot.exists() {
                    let name             = snapshot.value!["name"] as? String
                    let displayName      = snapshot.value!["username"] as! String
                    let imageURL         = snapshot.value!["profileImageURL"] as! String
                    user = User(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: nil, bio: nil)
                    dataCache.setObject(user!, forKey: "user-\(uid)")
                }
                completionHandler(user: user)
                
            })
        }
    }
    
    static func getUserWithCheck(uid:String, check:Int, completionHandler: (user:User?, check:Int)->()) {
        
        if let cachedUser = dataCache.objectForKey("user-\(uid)") as? User {
            completionHandler(user: cachedUser, check: check)
            
        } else {
            ref.child("users/profile/basic/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                var user:User?
                if snapshot.exists() {
                    let name             = snapshot.value!["name"] as? String
                    let displayName      = snapshot.value!["username"] as! String
                    let imageURL         = snapshot.value!["profileImageURL"] as! String
                    user = User(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: nil, bio: nil)
                    dataCache.setObject(user!, forKey: "user-\(uid)")
                }
                completionHandler(user: user, check: check)
                
            })
        }
    }
    
    static func getUserFullProfile(user:User, completionHandler: (user:User)->()) {
        if user.bio != nil && user.largeImageURL != nil {
            completionHandler(user: user)
        }
        if user.bio == nil || user.largeImageURL == nil {
            let ref = FirebaseService.ref.child("users/profile/full/\(user.getUserId())")
            ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if snapshot.exists() {
                    user.largeImageURL = snapshot.value!["largeProfileImageURL"] as? String
                    user.bio           = snapshot.value!["bio"] as? String

                    let uid = user.getUserId()
                    dataCache.removeObjectForKey("user-\(uid)")
                    dataCache.setObject(user, forKey: "user-\(uid)")
                }
                completionHandler(user: user)
            })
        }
    }
    
    static func sendFCMToken() {
        if let token = FIRInstanceID.instanceID().token() {
            if let user = mainStore.state.userState.user {
                let fcmRef = ref.child("users/FCMToken/\(user.getUserId())")
                fcmRef.setValue(token)
            }
        }
        
        
    }
    

    internal static func sendImage(upload:Upload, completionHandler:(()->())) {
        
        //If upload has no destination do not upload it
        if !upload.toProfile && !upload.toStory && upload.locationKey == "" { return }
        
        if upload.image == nil { return }
        
        let uid = mainStore.state.userState.uid

        
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key

        if let data = UIImageJPEGRepresentation(upload.image!, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            var uploadingMurmer = Murmur(title: "Uploading...")
            uploadingMurmer.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
            uploadingMurmer.titleColor = UIColor.lightGrayColor()
            show(whistle: uploadingMurmer, action: .Show(60.0))
            
            // Upload file and metadata to the object
            let uploadTask = storageRef.child("user_uploads/\(postKey))").putData(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    // HANDLE ERROR
                    hide()
                    var murmur = Murmur(title: "Unable to upload.")
                    murmur.backgroundColor = errorColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(5.0))
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    let obj = [
                        "author": uid,
                        "toProfile": upload.toProfile,
                        "toStory": upload.toStory,
                        "toLocation": upload.locationKey != "",
                        "location": upload.locationKey,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 5
                    ]
                    dataRef.child("meta").setValue(obj, withCompletionBlock: { error, _ in
                        hide()
                        if error == nil {
                            var murmur = Murmur(title: "Image uploaded!")
                            murmur.backgroundColor = accentColor
                            murmur.titleColor = UIColor.whiteColor()
                            show(whistle: murmur, action: .Show(3.0))
                        } else {
                            var murmur = Murmur(title: "Unable to upload.")
                            murmur.backgroundColor = errorColor
                            murmur.titleColor = UIColor.whiteColor()
                            show(whistle: murmur, action: .Show(5.0))
                        }
                    })

                }
            }
            completionHandler()
        }
        
    }
    
    
    
    internal static func uploadVideo(upload:Upload, completionHandler:(success:Bool)->()){
        
        //If upload has no destination do not upload it
        if !upload.toProfile && !upload.toStory && upload.locationKey == "" { return }
        
        if upload.videoURL == nil { return }
        
        let uid = mainStore.state.userState.uid
        let url = upload.videoURL!
        
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key
        
        var uploadingMurmer = Murmur(title: "Uploading...")
        uploadingMurmer.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
        uploadingMurmer.titleColor = UIColor.lightGrayColor()
        show(whistle: uploadingMurmer, action: .Show(60.0))
        completionHandler(success: true)
        
        uploadVideoStill(url, postKey: postKey, completionHandler: { thumbURL in
            
            
            let data = NSData(contentsOfURL: url)
            
            let metadata = FIRStorageMetadata()
            let contentTypeStr = "video/mp4"
            let playerItem = AVAsset(URL: url)
            let length = CMTimeGetSeconds(playerItem.duration)
            metadata.contentType = contentTypeStr
            
            let uploadTask = storageRef.child("user_uploads/videos/\(postKey)").putData(data!, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // HANDLE ERROR
                    hide()
                    var murmur = Murmur(title: "Unable to upload.")
                    murmur.backgroundColor = errorColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(5.0))
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    let obj = [
                        "author": uid,
                        "toProfile": upload.toProfile,
                        "toStory": upload.toStory,
                        "toLocation": upload.locationKey != "",
                        "location": upload.locationKey,
                        "videoURL": downloadURL!.absoluteString,
                        "url": thumbURL,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": length
                    ]
                    dataRef.child("meta").setValue(obj, withCompletionBlock: { error, _ in
                        hide()
                        if error == nil {
                            
                            var murmur = Murmur(title: "Video uploaded!")
                            murmur.backgroundColor = accentColor
                            murmur.titleColor = UIColor.whiteColor()
                            show(whistle: murmur, action: .Show(3.0))
                        } else {
                            var murmur = Murmur(title: "Unable to upload.")
                            murmur.backgroundColor = errorColor
                            murmur.titleColor = UIColor.whiteColor()
                            show(whistle: murmur, action: .Show(5.0))
                        }
                    })
                }
            }
            
        })
    }
    
    internal static func removeItemFromLocation(item:StoryItem, completionHandler:(()->())) {
        let locationRef = ref.child("locations/uploads/\(item.locationKey)/\(item.authorId)/\(item.key)")
        locationRef.removeValueWithCompletionBlock({ error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toLocation")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toLocation = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)")
                        completionHandler()
                    } else {
                        completionHandler()
                    }
                })
            } else {
                completionHandler()
            }
        })
    }
    
    internal static func removeItemFromStory(item:StoryItem, completionHandler:(()->())) {
        let storyRef = ref.child("users/activity/\(item.authorId)/\(item.key)")
        storyRef.removeValueWithCompletionBlock({ error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toStory")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toStory = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)")
                        completionHandler()
                    } else {
                        completionHandler()
                    }
                })
            } else {
                completionHandler()
            }
        })
    }
    
    internal static func removeItemFromProfile(item:StoryItem, completionHandler:(()->())) {
        let storyRef = ref.child("users/uploads/\(item.authorId)/\(item.key)")
        storyRef.removeValueWithCompletionBlock({ error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toProfile")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toProfile = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)")
                        completionHandler()
                    } else {
                        completionHandler()
                    }
                })
            } else {
                completionHandler()
            }
        })
    }
    
    private static func uploadVideoStill(url:NSURL, postKey:String, completionHandler:(thumb_url:String)->()) {
        if let videoStill = generateVideoStill(url) {
            if let data = UIImageJPEGRepresentation(videoStill, 0.5) {
                let stillMetaData = FIRStorageMetadata()
                stillMetaData.contentType = "image/jpg"
                let uploadTask = storageRef.child("user_uploads/\(postKey)").putData(data, metadata: stillMetaData) { metadata, error in
                    if (error != nil) {
                        
                    } else {
                        let thumbURL = metadata!.downloadURL()!
                        completionHandler(thumb_url: thumbURL.absoluteString)
                    }
                }
            }
        }
    }
    
    private static func generateVideoStill(url:NSURL) -> UIImage?{
        do {
            let asset = AVAsset(URL: url)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
            let image = UIImage(CGImage: cgImage)
            return image
        } catch let error as NSError {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    
    
    static func getLocationEvents(locationKey:String, completionHandler: (events:[Event])->()) {
        getLocationEventKeys(locationKey, completionHandler: { eventKeys in
            var events = [Event]()
            var count = 0
            for key in eventKeys {
                getEvent(key, completionHandler: { event in
                    if event != nil {
                        if !event!.hasPassed() {
                            events.append(event!)
                        }
                    }
                    count += 1
                    if count >= eventKeys.count {
                        dispatch_async(dispatch_get_main_queue(), {
                            completionHandler(events: events)
                        })
                    }
                })
            }
        })
    }
    
    static func getLocationEventKeys(locationKey:String, completionHandler:(eventKeys:[String])->()) {
        let eventsRef = ref.child("locations/events/\(locationKey)")
        eventsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var events = [String]()
            if snapshot.exists() {
                for child in snapshot.children {
                    let eventKey = child.key!!
                    events.append(eventKey)
                }
            }
            print("events: \(events)")
            completionHandler(eventKeys: events)
        })
    }
    
    static func getEvent(eventKey:String, completionHandler:(event:Event?)->()) {
        if let cachedEvent = dataCache.objectForKey("event-\(eventKey)") as? Event {
            print("Event from cache: \(eventKey)")
            return completionHandler(event: cachedEvent)
        }
        
        let eventRef = ref.child("events/\(eventKey)")
        eventRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var event:Event?
            if snapshot.exists() {
                let name                = snapshot.value!["name"] as! String
                let dateString          = snapshot.value!["date"] as! String
                let imageUrl            = snapshot.value!["imageUrl"] as! String
                let date = getDateFromString(dateString)
                
                event = Event(key: eventKey, name: name, date: date, imageUrl: imageUrl)
                dataCache.setObject(event!, forKey: "event-\(eventKey)")
            }
            
            completionHandler(event: event)
        })
    }
    
    static func deletePost(postItem:StoryItem, completionHandler:()->()) {
        let postKey = postItem.getKey()
        let uid = mainStore.state.userState.uid
        let location = postItem.getLocationKey()
        
        let locationRef = ref.child("locations/uploads/\(location)/\(postKey)")
        let userRef = ref.child("users/uploads/\(uid)/\(postKey)")
        let postRef = ref.child("uploads/\(postKey)")
        locationRef.removeValueWithCompletionBlock({ error, ref in
            userRef.removeValueWithCompletionBlock({ error, ref in
                postRef.updateChildValues(["delete":true])
                completionHandler()
            })
        })
    }
    
    static func getUpload(key:String, completionHandler: (item:StoryItem?)->()) {
        
        if let cachedUpload = dataCache.objectForKey("upload-\(key)") as? StoryItem {
            return completionHandler(item: cachedUpload)
        }
        
        let postRef = ref.child("uploads/\(key)/meta")
        postRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var item:StoryItem?
            if snapshot.exists() {
                if !snapshot.hasChild("delete") {
                    let key = key
                    let authorId = snapshot.value!["author"] as! String
                    let locationKey = snapshot.value!["location"] as! String
                    let downloadUrl = NSURL(string: snapshot.value!["url"] as! String)!
                    let contentTypeStr = snapshot.value!["contentType"] as! String
                    var contentType = ContentType.Invalid
                    var videoURL:NSURL?
                    if contentTypeStr == "image/jpg" {
                        contentType = .Image
                    } else if contentTypeStr == "video/mp4" {
                        contentType = .Video
                        if snapshot.hasChild("videoURL") {
                            videoURL = NSURL(string: snapshot.value!["videoURL"] as! String)!
                        }
                    }
                    
                    let toProfile = snapshot.value!["toProfile"] as! Bool
                    let toStory = snapshot.value!["toStory"] as! Bool
                    let toLocation = snapshot.value!["toLocation"] as! Bool
                    
                    let dateCreated = snapshot.value!["dateCreated"] as! Double
                    let length = snapshot.value!["length"] as! Double

                    item = StoryItem(key: key, authorId: authorId,locationKey: locationKey, downloadUrl: downloadUrl,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, toProfile: toProfile, toStory: toStory, toLocation: toLocation)
                    dataCache.setObject(item!, forKey: "upload-\(key)")
                }
            }
            
            return completionHandler(item: item)
        })
    }
    
    
    
    static func downloadStory(postKeys:[String], completionHandler: (story:[StoryItem])->()) {
        var story = [StoryItem]()
        var loadedCount = 0
        for postKey in postKeys {
            
            getUpload(postKey, completionHandler: { item in
            
                if let _ = item {
                    story.append(item!)
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
    
    static func downloadUsers(userIds:[String], completionHandler: (users:[User])->()) {
        var users = [User]()
        var loadedCount = 0
        for userId in userIds {
            getUser(userId, completionHandler: { _user in
                if let user = _user {
                    users.append(user)
                }
                loadedCount += 1
                if loadedCount >= userIds.count {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(users: users)
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
    
    static func handleFriendAction(uid:String, status:FriendStatus) {
        switch status {
        case .FRIENDS:
            break
        case .NOT_FRIENDS:
            FirebaseService.sendFriendRequest(uid)
            break
        case .PENDING_INCOMING:
            FirebaseService.acceptFriendRequest(uid)
            break
        case .PENDING_INCOMING_SEEN:
            FirebaseService.acceptFriendRequest(uid)
            break
        case .PENDING_OUTGOING:
            break
        default:
            break
        }
    }
    
    
    static func sendFriendRequest(friend_uid:String) {
        
        let uid = mainStore.state.userState.uid
        print("FRIEND UID \(friend_uid)")
        let userRef = FirebaseService.ref.child("users/social/requestsOut/\(uid)/\(friend_uid)")
        userRef.setValue(false)
        print("USERREF: \(userRef)")
        let friendRef = FirebaseService.ref.child("users/social/requestsIn/\(friend_uid)/\(uid)")
        friendRef.setValue(false, withCompletionBlock: {
            error, ref in
        })
    }
    
    static func acceptFriendRequest(friend_uid:String) {
        print("ACCEPT FRIEND REQUEST: \(friend_uid)")
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
    
    static func addView(postKey:String, uid:String) {
        
        let postRef = ref.child("uploads/\(postKey)")
        postRef.child("views/\(uid)").observeEventType(.Value, withBlock: { snapshot in
            if !snapshot.exists() {
                print("ADDING VIEW")
                postRef.child("views/\(uid)").setValue(true, withCompletionBlock: { error, ref in
                    if error == nil {
                        postRef.child("meta/views").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                            if var numViews = currentData.value as? Int {
                                
                                numViews += 1
                                currentData.value = numViews
                                
                                return FIRTransactionResult.successWithValue(currentData)
                            }
                            else {
                                currentData.value = 1
                                return FIRTransactionResult.successWithValue(currentData)
                            }
                        }) { (error, committed, snapshot) in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                })
            } else {
                print("View already exists")
            }
        })
        
    }
    
    
    static func reportItem(item:StoryItem, type:ReportType, showNotification:Bool, completionHandler:((success:Bool)->())) {
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid)/\(item.getKey())")
        let value: [String: AnyObject] = [
        "type": type.rawValue,
        "timeStamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            if error == nil {
                if showNotification {
                    var murmur = Murmur(title: "Report Sent!")
                    murmur.backgroundColor = accentColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(3.0))

                }
            } else {
                if showNotification {
                    var murmur = Murmur(title: "Report failed to send.")
                    murmur.backgroundColor = errorColor
                    murmur.titleColor = UIColor.whiteColor()
                    show(whistle: murmur, action: .Show(3.0))
                }
                completionHandler(success: false)
            }
        })
    }

    

}

enum ReportType:String {
    case Inappropriate = "Inappropriate"
    case Spam          = "Spam"
}

func deleteFileAtPath(url:NSURL) {
    let fileManager = NSFileManager.defaultManager()
    
    // Delete 'hello.swift' file
    
    do {
        try fileManager.removeItemAtPath(url.absoluteString)
    }
    catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
    }
}
