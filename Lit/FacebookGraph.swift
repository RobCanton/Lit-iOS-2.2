//
//  FacebookGraph.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-09.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class FacebookGraph {

    
    static func requestFacebookFriendIds(completionHandler:(fb_ids:[String])->()) {
        let request = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            if error != nil {
                //let errorMessage = error.localizedDescription
                /* Handle error */
            }
            else {
                /*  handle response */
                var fb_ids = [String]()
                let data = result["data"] as! [NSDictionary]
                for item in data {
                    if let id = item["id"] as? String {
                        fb_ids.append(id)
                    }
                }
                completionHandler(fb_ids: fb_ids)
            }
        }
    }
    
    static func getFacebookFriends(completionHandler:(userIds:[String])->()) {
        
        requestFacebookFriendIds({ fb_ids in
            var _users = [String]()
            var count = 0
            for id in fb_ids {
                
                let ref = FirebaseService.ref.child("users/facebook/\(id)")
                print(ref)
                ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if snapshot.exists()
                    {
                        print(snapshot.value!)
                        _users.append(snapshot.value! as! String)
                    }
                    count += 1
                    if count >= fb_ids.count {
                        completionHandler(userIds: _users)
                    }
                })
            }
            
        })
        
        
    }
}