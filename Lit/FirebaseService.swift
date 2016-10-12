//
//  FirebaseService.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import ReSwiftRouter
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
        ref.child("users_public/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var user:User?
            if snapshot.exists() {
                let displayName = snapshot.value!["username"] as! String
                let imageUrl    = snapshot.value!["smallProfilePicURL"] as! String
                let largeImageUrl    = snapshot.value!["largeProfilePicURL"] as! String
                user = User(uid: uid, displayName: displayName, imageUrl: imageUrl, largeImageUrl: largeImageUrl)
            }

            completionHandler(user: user)
            
        })
    }
    

    internal static func sendImage(image:UIImage) -> FIRStorageUploadTask? {
        // Data in memory
        let city = mainStore.state.userState.activeCity!
        let activeLocationKey = mainStore.state.userState.activeLocationKey
        
        let dataRef = ref.child("uploads").childByAutoId()

        if let data = UIImageJPEGRepresentation(image, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = storageRef.child("user_uploads/\(dataRef.key))").putData(data, metadata: metadata) { metadata, error in
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
                        "length": 4

                    ]
                    dataRef.setValue(obj, withCompletionBlock: { error, _ in
                        if error == nil {
                            let locationRef = ref.child("locations/\(city.getKey())/\(activeLocationKey)/uploads/\(dataRef.key)")
                            locationRef.setValue([dataRef.key:true])
                            let userRef = ref.child("users_public/\(mainStore.state.userState.uid)/uploads/\(dataRef.key)")
                            userRef.setValue([dataRef.key:true])
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
        let uploadTask = storageRef.child("user_uploads/\(city.getKey())/\(saveRef.key))").putData(data!, metadata: metadata) { metadata, error in
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
                    "length": length
                    ])
            }
        }
        
        return uploadTask
    }
    
    static func downloadStory(postKeys:[String], completionHandler: (story:[StoryItem])->()) {
        var story = [StoryItem]()
        var loadedCount = 0
        for postKey in postKeys {
            let postRef = FirebaseService.ref.child("uploads/\(postKey)")
            
            postRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                if snapshot.exists() {
                    let key = snapshot.key
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
                    
                    let storyItem = StoryItem(key: key, authorId: authorId,locationKey: locationKey, downloadUrl: downloadUrl, contentType: contentType, dateCreated: dateCreated, length: length)
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
    

}
