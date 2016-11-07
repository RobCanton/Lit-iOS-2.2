//
//  LocationService.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import SwiftyJSON


class LocationService {

    static private let ref = FIRDatabase.database().reference().child("locations")
    
    static func requestNearbyLocations(latitude:Double, longitude:Double) {
        let uid = mainStore.state.userState.uid
        let url = NSURL(string: "\(apiURL)/nearby/50/\(latitude)/\(longitude)")
        print("Requesting Nearby Locations: \(url!.absoluteString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                self.extractFeedFromJSON(data!)
            }
        }
        
        task.resume()
    }
    
    static func extractFeedFromJSON(data:NSData) {
        var locationKeys = [String]()
        let json = JSON(data: data)
        print("EXTRACTING DATA")
        for (index,key):(String, JSON) in json["locations"] {
            
            locationKeys.append(key.stringValue)
        }
        
        getLocations(locationKeys, completionHandler:  { locations in
            
            if compareLocationsList(locations, listB: mainStore.state.locations) {
                print("Locations are equal. No action required")
            } else {
                print("Locations changed. Dispatch required")
                Listeners.stopListeningToLocations()
                mainStore.dispatch(LocationsRetrieved(locations: locations))
                Listeners.startListeningToLocations()
            }
            
            
        })
    }
    
    static func compareLocationsList(listA: [Location] , listB: [Location]) -> Bool {
        
        if listA.count != listB.count {
            return false
        }
        
        let sortedListA = listA.sort({ $0.getKey() > $1.getKey()})
        let sortedListB = listB.sort({ $0.getKey() > $1.getKey()})
        
        for i in 0 ..< sortedListA.count {
            if sortedListA[i].getKey() != sortedListB[i].getKey() {
                return false
            }
        }
        
        return true
    }
    
    
    static func getLocations(locationKeys:[String], completionHandler:(locations: [Location]) -> ()) {
        var locations = [Location]()
        var count = 0
        
        for key in locationKeys {
            getLocation(key, completionHandler: { location in
                if location != nil {
                    locations.append(location!)
                }
                count += 1
                
                if count >= locationKeys.count {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(locations: locations)
                    })
                }
            })
        }
    }
    
    static func getLocation(locationKey:String, completionHandler:(location:Location?)->()) {
        let locRef = FirebaseService.ref.child("locations/info/\(locationKey)")
        locRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var location:Location?
            if snapshot.exists() {
                let key         = snapshot.key
                let name        = snapshot.value!["name"] as! String
                let lat         = snapshot.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                let lon         = snapshot.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                let imageURL    = snapshot.value!["imageURL"] as! String
                let address     = snapshot.value!["address"] as! String
                
                location = Location(key: key, name: name, latitude: lat, longitude: lon, imageURL: imageURL, address: address)
            }
            completionHandler(location: location)
        })
    }
    
    
}