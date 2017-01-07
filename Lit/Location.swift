//
//  Location.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

//
import CoreLocation

class Location:NSObject, NSCoding {
    
    private var key:String                    // Key in database
    private var name:String
    private var coordinates:CLLocation
    private var imageURL:String
    private var address:String
    private var distance:Double?
    
    private var visitors = [String]()
    private var postKeys = [String]()

    private var friendsCount = 0
    
    var imageOnDiskURL:NSURL?
    
    
    init(key:String, name:String, latitude:Double, longitude: Double, imageURL:String, address:String)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = CLLocation(latitude: latitude, longitude: longitude)
        self.imageURL     = imageURL
        self.address      = address
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObjectForKey("key") as! String
        let name = decoder.decodeObjectForKey("name") as! String
        let latitude = decoder.decodeObjectForKey("latitude") as! Double
        let longitude = decoder.decodeObjectForKey("longitude") as! Double
        let imageURL = decoder.decodeObjectForKey("imageURL") as! String
        let address = decoder.decodeObjectForKey("address") as! String
        self.init(key:key, name:name, latitude:latitude, longitude: longitude, imageURL:imageURL, address:address)
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(key, forKey: "key")
        coder.encodeObject(name, forKey: "name")
        coder.encodeObject(coordinates.coordinate.latitude, forKey: "latitude")
        coder.encodeObject(coordinates.coordinate.longitude, forKey: "longitude")
        coder.encodeObject(imageURL, forKey: "imageURL")
        coder.encodeObject(address, forKey: "address")
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getName()-> String
    {
        return name
    }
    
    func getCoordinates() -> CLLocation
    {
        return coordinates
    }
    
    func getImageURL() -> String
    {
        return imageURL
    }
    
    func getAddress() -> String
    {
        return address
    }
    
    func findVisitor(uid:String) -> Int? {
        for i in 0 ..< visitors.count {
            let visitor = visitors[i]
            if visitor == uid {
                return i
            }
        }
        
        return nil
    }
    
    func addVisitor(visitor:String) {
        if findVisitor(visitor) == nil{
            visitors.append(visitor)
        }
    }
    
    func removeVisitor(_visitor:String) {
        
        if let i = findVisitor(_visitor) {
            visitors.removeAtIndex(i)
        }
    }
    
    func getVisitors() -> [String] {
        return visitors
    }
    
    func getVisitorsCount() -> Int {
        return visitors.count
    }
    
    func getFriendsCount() -> Int {
        return friendsCount
    }
    
    func addPost(key:String) {
        postKeys.append(key)
    }
    
    func removePost(_key:String) {
        for i in 0 ..< postKeys.count {
            let key = postKeys[i]
            if key == _key {
                postKeys.removeAtIndex(i)
                break
            }
        }
    }
    
    
    func getPostKeys() -> [String] {
        return postKeys
    }
    
    func collectInfo() {
        friendsCount = 0
        for visitor in visitors {
            if mainStore.state.friends.contains(visitor) {
                friendsCount += 1
            }
        }

    }
    
    func setDistance(distance:Double) {
        self.distance = distance
    }
    
    func getDistance() -> Double? {
        return distance
    }
    
//    func getImageFilePath() {
//        let  documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
//        let fileURL = documentsURL.URLByAppendingPathComponent("location_images").URLByAppendingPathComponent("\(key)).jpg")
//        if let content = UIImage(contentsOfFile: file.path!) {
//            
//        }
//    }
}