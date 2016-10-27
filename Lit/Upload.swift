//
//  File.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-26.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit


class Upload {
    
    private var userProfile = false
    private var locationKey:String = ""
    
    var image:UIImage?
    
    
    init(toUserProfile: Bool, locationKey:String)
    {
        self.userProfile = toUserProfile
        self.locationKey = locationKey
    }
    
    func toUserProfile() -> Bool {
        return userProfile
    }
    
    func toLocation() -> Bool {
        return locationKey != ""
    }
    
    func getLocationKey() -> String {
        return locationKey
    }
    
    
    
    

}