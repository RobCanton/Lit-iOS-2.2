//
//  UserService.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift

class UserService {
    
    
    
    static let ref = FIRDatabase.database().reference()
    
    static func uploadProfilePicture(largeImage:UIImage, smallImage:UIImage , completionHandler:(success:Bool, largeImageURL:String?, smallImageURL:String?)->()) {
        if let largeImageTask = uploadLargeProfilePicture(largeImage) {
            largeImageTask.observeStatus(.Success, handler: { largeImageSnapshot in
                if let smallImageTask = uploadSmallProfilePicture(smallImage) {
                    smallImageTask.observeStatus(.Success, handler: { smallImageSnapshot in
                        let largeImageURL = largeImageSnapshot.metadata!.downloadURL()!.absoluteString
                        let smallImageURL =  smallImageSnapshot.metadata!.downloadURL()!.absoluteString
                        completionHandler(success: true,largeImageURL: largeImageURL, smallImageURL: smallImageURL)
                    })
                    smallImageTask.observeStatus(.Failure, handler: { _ in completionHandler(success: false , largeImageURL: nil, smallImageURL: nil) })
                } else { completionHandler(success: false , largeImageURL: nil, smallImageURL: nil) }
            })
            largeImageTask.observeStatus(.Failure, handler: { _ in completionHandler(success: false , largeImageURL: nil, smallImageURL: nil) })
        } else { completionHandler(success: false , largeImageURL: nil, smallImageURL: nil)}
        
    }
    
    private static func uploadLargeProfilePicture(image:UIImage) -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}
        
        let imageRef = FirebaseService.storageRef.child("user_profiles/\(user.uid)/large")
        if let picData = UIImageJPEGRepresentation(image, 0.6) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            let uploadTask = imageRef.putData(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    private static func uploadSmallProfilePicture(image:UIImage) -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}
        
        let imageRef = FirebaseService.storageRef.child("user_profiles/\(user.uid)/small")
        if let picData = UIImageJPEGRepresentation(image, 0.9) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            let uploadTask = imageRef.putData(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    static func updateProfilePictureURL(largeURL:String, smallURL:String, completionHandler:()->()) {
        let uid = mainStore.state.userState.uid
        let basicRef = FIRDatabase.database().reference().child("users/profile/basic/\(uid)")
        basicRef.updateChildValues([
            "profileImageURL": smallURL
            ], withCompletionBlock: { error, ref in
                let fullRef = FIRDatabase.database().reference().child("users/profile/full/\(uid)")
                fullRef.updateChildValues([
                    "largeProfileImageURL": largeURL
                    ], withCompletionBlock: { error, ref in
                        
                        completionHandler()
                })
        })
    }

}