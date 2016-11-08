//
//  Reducer.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

struct AppReducer: Reducer {
    
    func handleAction(action: Action, state: AppState?) -> AppState {

        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            locations:LocationsReducer(action, state: state?.locations),
            cities:CitiesReducer(action, state: state?.cities),
            friends: FriendsReducer(action, state: state?.friends),
            friendRequestsIn: FriendRequestsInReducer(action, state: state?.friendRequestsIn),
            friendRequestsOut: FriendRequestsOutReducer(action, state: state?.friendRequestsOut),
            conversations: ConversationsReducer(action, state: state?.conversations)
        )
    }
}
