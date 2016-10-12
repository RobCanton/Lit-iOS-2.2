//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation

class User {
    private var uid: String
    private var displayName: String
    private var imageUrl: String
    private var largeImageUrl: String
    
    init(uid:String, displayName:String, imageUrl: String, largeImageUrl:String)
    {
        self.uid           = uid
        self.displayName   = displayName
        self.imageUrl      = imageUrl
        self.largeImageUrl = largeImageUrl
    }
    
    func getUserId() -> String {
        return uid
    }
    
    func getDisplayName() -> String {
        return displayName
    }
    
    func getImageUrl() -> String {
        return imageUrl
    }
    
    func getLargeImageUrl() -> String {
        return largeImageUrl
    }
    
}