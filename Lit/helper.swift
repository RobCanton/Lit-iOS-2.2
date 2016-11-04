//
//  helper.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

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


func printFonts() {
    let fontFamilyNames = UIFont.familyNames()
    for familyName in fontFamilyNames {
        print("------------------------------")
        print("Font Family Name = [\(familyName)]")
        let names = UIFont.fontNamesForFamilyName(familyName as! String)
        print("Font Names = [\(names)]")
    }
}


func getDateString(date:NSDate) -> String {
    let weekFromDay = NSDate().xDays(7)
    
    if date.timeIntervalSinceDate(weekFromDay) < 0 {
        if NSCalendar.currentCalendar().isDateInToday(date) {
            return "Tonight"
        } else if NSCalendar.currentCalendar().isDateInTomorrow(date) {
            return "Tomorrow"
        } else if NSCalendar.currentCalendar().isDateInYesterday(date) {
            return "Yesterday"
        }
        
        return date.dayOfTheWeek()
    }
    
    let formatter = NSDateFormatter()
    formatter.dateStyle = NSDateFormatterStyle.LongStyle
    formatter.timeStyle = .NoStyle
    
    return formatter.stringFromDate(date)
    
}

