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
    // Create a storage reference from our storage service
    
    // Get a reference to the storage service, using the default Firebase App
    
//    static func writeUser(user:FIRUser) {
//        let userInfo: [String : AnyObject] = [
//            "displayName": ((user.displayName ?? "").isEmpty ? "" : user.displayName!),
//            "photoUrl": ((user.photoURL?.absoluteString ?? "").isEmpty ? "" : user.photoURL!.absoluteString)
//            
//        ]
//
//        ref.child("users").child(user.uid).updateChildValues(userInfo)
//        ref.child("users").child(user.uid).updateChildValues(userInfo, withCompletionBlock: { error, ref in
//            getUser(user.uid, completionHandler: { _user in
//                if let user = _user {
//                    mainStore.dispatch(UserIsAuthenticated( user: user))
//                }
//            })
//        })
//    }
//    
    static func signOut() {
        try! FIRAuth.auth()!.signOut()
    }
    
//    static func listenToAuth() {
//        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
//            if let user = user {
//                // User is signed in.
//                getUser(user.uid, completionHandler: { _user in
//                    if _user != nil {
//                        mainStore.dispatch(UserIsAuthenticated( user: _user!))
//                    } else {
//                        writeUser(user)
//                    }
//                })
//            } else {
//                // No user is signed in.
//            }
//        }
//    }
    
    static func getUser(uid:String, completionHandler: (user:User?)->()) {
        ref.child("users_public/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var user:User?
            if snapshot.exists() {
                let displayName = snapshot.value!["username"] as! String
                let imageUrl    = snapshot.value!["smallProfilePicURL"] as! String
                user = User(uid: uid, displayName: displayName, imageUrl: imageUrl)
            }

            completionHandler(user: user)
            
        })
    }
    
    static func retrieveCities() {
        let refHandle = ref.child("cities")
            .observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                var cities = [City]()
                for city in snapshot.children {
                    let key = city.key!!
                    let name = city.value["name"] as! String
                    let lat = city.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                    let lon = city.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                    let coord = IGLocation(latitude: lat, longitude: lon)
                    let country = city.value["country"] as! String
                    let region = city.value["region"] as! String
                    
                    let city = City(key: key, name: name, coordinates: coord, country: country, region: region)
                    cities.append(city)
                }
                
                mainStore.dispatch(CitiesRetrieved(cities: cities))
            
        })
    }
    
    static func retrieveLocationsForCity(city:String) {
        let refHandle = ref.child("locations/\(city)").observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            var locations = [Location]()
            for child in snapshot.children {
                let key = child.key!!
                let name = child.value["name"] as! String
                let lat = child.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                let lon = child.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                let coord = CLLocation(latitude: lat, longitude: lon)
                let imageURL = child.value["imageURL"] as! String
                let address = child.value["address"] as! String
                let description = child.value["description"] as! String
                let number = child.value["number"] as! String
                let website = child.value["website"] as! String
                let storyCount = child.value["story_count"] as! Int

                let loc = Location(key: key, name: name, coordinates: coord, imageURL: imageURL, address: address, description: description, number: number, website: website, storyCount: storyCount)
                
                locations.append(loc)
            }
            mainStore.dispatch(LocationsRetrieved(locations: locations))
            
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
                            let userRef = ref.child("users/\(mainStore.state.userState.uid)/uploads/\(dataRef.key)")
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
