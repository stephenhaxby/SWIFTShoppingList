//
//  Utility.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 22/03/2016.
//  Copyright © 2016 Stephen Haxby. All rights reserved.
//

import EventKit

class Utility {
    
    static var defaults : NSUserDefaults {
        
        get {
            
            return NSUserDefaults.standardUserDefaults()
        }
    }
    
    static func itemIsInShoppingCart(reminder : EKReminder) -> Bool {
        
        if reminder.completed && reminder.notes != nil {
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            
            if let reminderDate : NSDate = dateFormatter.dateFromString(reminder.notes!) {
                
                if let shoppingCartExpiryTime : NSDate = defaults.objectForKey(Constants.ClearShoppingListExpire) as? NSDate {
                    
                    let shoppingCartExpiryTime : NSDateComponents =  NSDateManager.getDateComponentsFromDate(shoppingCartExpiryTime)
                    
                    let expiryTime : NSDate = NSDateManager.addHoursAndMinutesToDate(reminderDate, hours: shoppingCartExpiryTime.hour, Minutes: shoppingCartExpiryTime.minute)
                    
                    return NSDateManager.dateIsBeforeDate(expiryTime, date2: NSDate())
                }
                else {
                    
                    return true
                }
            }
        }
        
        return false
    }
}