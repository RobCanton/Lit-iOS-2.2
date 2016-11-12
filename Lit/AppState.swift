//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import CoreLocation
import IngeoSDK


struct AppState: StateType {
    var userState: UserState
    var locations: [Location]
    var cities: [City]
    var friends = Tree<String>()
    var friendRequestsIn = [String:Bool]()
    var friendRequestsOut = [String:Bool]()
    var conversations = [Conversation]()
    var socialState: SocialState
}

struct UserState {
    var flow: FlowState = .None
    var isAuth: Bool = false
    var uid: String = ""
    var user:User?
    var activeLocationKey:String=""
}

struct SocialState {
    var followers = Tree<String>()
    var following = Tree<String>()
}
