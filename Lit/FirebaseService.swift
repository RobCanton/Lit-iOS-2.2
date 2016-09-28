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
    
    static func writeUser(user:FIRUser) {
        let userInfo: [String : AnyObject] = [
            "displayName": ((user.displayName ?? "").isEmpty ? "" : user.displayName!),
            "email": ((user.email ?? "").isEmpty ? "" : user.email!),
            "photoUrl": ((user.photoURL?.absoluteString ?? "").isEmpty ? "" : user.photoURL!.absoluteString)
            
        ]

        ref.child("users").child(user.uid).updateChildValues(userInfo)
    }
    
    static func signOut() {
        try! FIRAuth.auth()!.signOut()
    }
    
    static func listenToAuth() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in.
                mainStore.dispatch(UserIsAuthenticated(uid: user.uid))
            } else {
                // No user is signed in.
            }
        }
    }
    
    static func getUser(uid:String, completionHandler: (user:User)->()) {
        ref.child("users/\(uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let displayName = snapshot.value!["displayName"] as! String
            let email       = snapshot.value!["email"] as! String
            let imageUrl    = snapshot.value!["photoUrl"] as! String
            
            completionHandler(user: User(uid: uid, displayName: displayName, email: email, imageUrl: imageUrl))
            
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
        let saveRef = ref.child("/uploads/\(city.getKey())/\(activeLocationKey)").childByAutoId()

        
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = storageRef.child("user_uploads/\(city.getKey())/\(saveRef.key))").putData(data, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    saveRef.setValue([
                        "author": mainStore.state.userState.uid,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 5

                    ])
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
    
    static func downloadLocationStory(locationIndex:Int) {
        
        let location = mainStore.state.locations[locationIndex]
        let city = mainStore.state.userState.activeCity!.getKey()
        let refHandle = ref.child("uploads/\(city)/\(location.getKey())").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            var story = [StoryItem]()
            for child in snapshot.children {
                let key = child.key!!
                let authorId = child.value["author"] as! String
                let downloadUrl = child.value["url"] as! String
                let contentTypeStr = child.value["contentType"] as! String
                var contentType: ContentType
                if contentTypeStr == "image/jpg" {
                    contentType = .Image
                } else {
                    contentType = .Video
                }
                
                let dateCreated = child.value["dateCreated"] as! Double
                let length = child.value["length"] as! Double
                
                let storyItem = StoryItem(key: key, authorId: authorId, downloadUrl: downloadUrl, contentType: contentType, dateCreated: dateCreated, length: length)
                story.append(storyItem)
            }
            
            mainStore.dispatch(LocationStoryLoaded(locationIndex: locationIndex, story: story))
            
        })
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
