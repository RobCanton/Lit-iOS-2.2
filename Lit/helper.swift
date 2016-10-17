//
//  helper.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation

// convert an NSDate object to a timestamp string

func convertToTimestamp(date: NSDate) -> String {
    return String(Int64(date.timeIntervalSince1970 * 1000))
}

// Convert the timestamp string to an NSDate object

func convertFromTimestamp(seconds: String) -> NSDate {
    let time = (seconds as NSString).doubleValue/1000.0
    return NSDate(timeIntervalSince1970: NSTimeInterval(time))
}

// format the date using a timestamp

func formatDateTime(timestamp: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle
    dateFormatter.timeStyle = .ShortStyle
    let date = convertFromTimestamp(timestamp)
    return dateFormatter.stringFromDate(date)
}


func getLikesString(numLikes:Int) -> String{
    if numLikes == 0 {
        return ""
    } else if numLikes == 1 {
        return "1 like"
    }
    
    return "\(numLikes) likes"
    
}