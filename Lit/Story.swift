//
//  Story.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

enum UserStoryState {
    case NotLoaded, LoadingItemInfo, ItemInfoLoaded, LoadingContent, ContentLoaded
}

protocol StoryProtocol {
    func stateChange(state: UserStoryState)
}

class UserStory: ItemDelegate {
    private var user_id:String
    private var postKeys:[String]
    private var date:NSDate
    
    
    var delegate:StoryProtocol?

    var items:[StoryItem]?
    var state:UserStoryState = .NotLoaded
        {
        didSet {
            delegate?.stateChange(state)
        }
    }
    
    init(user_id:String, postKeys:[String], timestamp:Double) {
        self.user_id = user_id
        self.postKeys = postKeys
        self.date  = NSDate(timeIntervalSince1970: timestamp/1000)
    }
    
    func getUserId() -> String {
        return user_id
    }
    
    func getPostKeys() -> [String] {
        return postKeys
    }
    
    func getDate() -> NSDate {
        return date
    }
    
    func hasViewedAll() -> Bool {
        guard let _items = self.items else { return false }
        for item in _items {
            if !item.hasViewed() {
                return false
            }
        }
        
        return true
    }
    
    
    
    
    func determineState() {
        if needsDownload() {
            if items == nil {
                state = .NotLoaded
            } else {
                state = .ItemInfoLoaded
            }
        } else {
            state = .ContentLoaded
        }
    }
    
    /**
     # downloadItems
     Download the full data and create a Story Item for each post key.
     
     * Successful download results set state to ItemInfoLoaded
     * If data already downloaded sets state to ContentLoaded

    */
    func downloadItems() {
        if state == .NotLoaded {
            state = .LoadingItemInfo
            FirebaseService.downloadStory(postKeys, completionHandler: { items in
                
                self.items = items.sort({
                    return $0 < $1
                })
                self.state = .ItemInfoLoaded
                if !self.needsDownload() {
                    self.state = .ContentLoaded
                }

            })
        } else if items != nil {
            if !self.needsDownload() {
                self.state = .ContentLoaded
            }
        }
    }
    
    func needsDownload() -> Bool {
        if items != nil {
            for item in items! {
                if item.needsDownload() {
                    return true
                }
            }
            return false
        }
        return true
    }
    
    
    func itemDownloaded() {
        if !needsDownload() {
            self.state = .ContentLoaded
        }
    }
    
    func downloadStory() {
        if items != nil {
            state = .LoadingContent
            for item in items! {
                item.delegate = self
                item.download()
            }
        }
    }
    

    
    func printDescription() {
        print("USER STORY: \(user_id)")
        
        for key in postKeys {
            print(" * \(key)")
        }
        
        print("\n")
    }
}

func < (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedAscending
}

func > (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedDescending
}

func == (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedSame
}

//func findStoryByUserID(uid:String, stories:[Story]) -> Int? {
//    for i in 0 ..< stories.count {
//        if stories[i].author_uid == uid {
//            return i
//        }
//    }
//    return nil
//}
//
//func sortStoryItems(items:[StoryItem]) -> [Story] {
//    var stories = [Story]()
//    for item in items {
//        if let index = findStoryByUserID(item.getAuthorId(), stories: stories) {
//            stories[index].addItem(item)
//        } else {
//            let story = Story(author_uid: item.getAuthorId())
//            story.addItem(item)
//            stories.append(story)
//        }
//    }
//    
//    return stories
//}

//func < (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedAscending
//}
//
//func == (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedSame
//}