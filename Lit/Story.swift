//
//  Story.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

func findStoryByUserID(uid:String, stories:[Story]) -> Int? {
    for i in 0 ..< stories.count {
        if stories[i].author_uid == uid {
            return i
        }
    }
    return nil
}

func sortStoryItems(items:[StoryItem]) -> [Story] {
    var stories = [Story]()
    for item in items {
        if let index = findStoryByUserID(item.getAuthorId(), stories: stories) {
            stories[index].addItem(item)
        } else {
            let story = Story(author_uid: item.getAuthorId())
            story.addItem(item)
            stories.append(story)
        }
    }
    
    return stories
}


enum StoryState {
    case NotLoaded, Loading, Loaded
}
class Story: NSObject, Comparable {
    
    private var author_uid:String
    
    private var items = [StoryItem]()
    
    var state:StoryState = StoryState.NotLoaded

    init(author_uid:String)
    {
        self.author_uid = author_uid
        
        super.init()
    }
    
    func getAuthorID() -> String {
        return author_uid
    }
    
    func addItem(item:StoryItem) {
        items.append(item)
        state = .NotLoaded
        
    }
    
    func getItems() -> [StoryItem] {
        return items
    }
    
    func getMostRecentItem() -> StoryItem? {
        if items.count > 0 {
            return items[items.count-1]
        }
        return nil
    }
    
    func needsDownload() -> Bool {
        for item in items {
            if item.needsDownload() {
                return true
            }
        }
        return false
    }

    
    func downloadStory(completionHandler:(complete:Bool)->()) {
        
        
        state = .Loading
        var count = 0
        for item in items {            
            item.download({ success in
                count += 1
                if count >= self.items.count {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.state = .Loaded
                        completionHandler(complete: true)
                    })
                }
            })
        }
    }
}

func < (lhs: Story, rhs: Story) -> Bool {
    let lhs_item = lhs.getMostRecentItem()!
    let rhs_item = rhs.getMostRecentItem()!
    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedAscending
}

func == (lhs: Story, rhs: Story) -> Bool {
    let lhs_item = lhs.getMostRecentItem()!
    let rhs_item = rhs.getMostRecentItem()!
    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedSame
}