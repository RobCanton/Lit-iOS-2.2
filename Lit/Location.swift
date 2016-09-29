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
    private var imageURL:String?
    private var address:String
    private var description:String
    private var number:String
    private var website:String
    var isActive: Bool = false
    private var storyCount: Int?
    
    private var story: [StoryItem]?
    
    private var visitors = [String]()
    
    private var postKeys = [String]()

    private var friendsCount = 0
    
    
    init(key:String, name:String, coordinates:CLLocation, imageURL:String, address:String, description:String, number:String, website:String,storyCount: Int)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = coordinates
        self.imageURL     = imageURL
        self.address      = address
        self.description  = description
        self.number       = number
        self.website      = website
        self.storyCount   = storyCount
        
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
    
    func getImageURL() -> String?
    {
        return imageURL
    }
    
    func getAddress() -> String?
    {
        return address
    }
    
    func getDescription() -> String
    {
        return description
    }
    
    func getNumber() -> String
    {
        return number
    }
    
    func getWebsite() -> String
    {
        let s = website.stringByReplacingOccurrencesOfString("http://", withString: "")
        let t = s.stringByReplacingOccurrencesOfString("www.", withString: "")
        return t
    }
    
    func setStory(story:[StoryItem]) {
        self.story = story
    }
    
    func getStory() -> [StoryItem]? {
        return self.story
    }
    
    func getStoryCount() -> Int? {
        return storyCount
    }
    
    func addVisitor(visitor:String) {
        visitors.append(visitor)
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