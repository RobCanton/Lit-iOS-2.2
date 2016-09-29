//
//  LocationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-28.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

func LocationsReducer(action: Action, state:[Location]?) -> [Location] {
    var state = state ?? []
    
    switch action {
    case _ as LocationsRetrieved:
        let a = action as! LocationsRetrieved
        state = a.locations
        break
    case _ as LocationStoryLoaded:
        let a = action as! LocationStoryLoaded
        let index = a.locationIndex
        state[index].setStory(a.story)
        break
    case _ as AddVisitorToLocation:
        let a = action as! AddVisitorToLocation
        state[a.locationIndex].addVisitor(a.uid)
        break
    case _ as RemoveVisitorFromLocation:
        let a = action as! RemoveVisitorFromLocation
        state[a.locationIndex].removeVisitor(a.uid)
    case _ as AddPostToLocation:
        let a = action as! AddPostToLocation
        state[a.locationIndex].addPost(a.key)
        break
    case _ as RemovePostFromLocation:
        let a = action as! RemovePostFromLocation
        state[a.locationIndex].removePost(a.key)
        break
    default:
        break
    }
    return state
}