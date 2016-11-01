//
//  Location.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

//
import CoreLocation

class Location {
    
    private var key:String                    // Key in database
    private var name:String
    private var coordinates:CLLocation
    private var imageURL:String
    private var address:String

    var isActive: Bool = false
    
    private var story: [StoryItem]?
    
    private var visitors = [String]()
    
    private var postKeys = [String]()

    private var friendsCount = 0
    
    var imageOnDiskURL:NSURL?
    
    
    init(key:String, name:String, coordinates:CLLocation, imageURL:String, address:String)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = coordinates
        self.imageURL     = imageURL
        self.address      = address
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
    
    
    func setStory(story:[StoryItem]) {
        self.story = story
    }
    
    func getStory() -> [StoryItem]? {
        return self.story
    }
    
    func addVisitor(visitor:String) {
        if isFriend(visitor) {
            visitors.insert(visitor, atIndex: 0)
        } else {
            visitors.append(visitor)
        }
    }
    
    func removeVisitor(_visitor:String) {
        for i in 0 ..< visitors.count {
            let visitor = visitors[i]
            if visitor == _visitor {
                visitors.removeAtIndex(i)
                break
            }
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
}