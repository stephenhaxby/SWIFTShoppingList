//
//  Utility.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 22/03/2016.
//  Copyright © 2016 Stephen Haxby. All rights reserved.
//

import EventKit
import UIKit

class Utility {
    
    static var defaults : UserDefaults {
        
        get {
            
            return UserDefaults.standard
        }
    }
    
    func getSubviewsOfView<T>(view : UIView) -> [T] {
        var viewsOfType = [T]()
        
        for subview in view.subviews {
            
            viewsOfType += getSubviewsOfView(view: subview)
            
            if subview is T {
                viewsOfType.append(subview as! T)
            }
        }
        
        return viewsOfType
    }
    
    static func itemIsInShoppingCart(_ reminder : ShoppingListItem) -> Bool {
        
        if reminder.completed && reminder.notes != nil {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            dateFormatter.timeStyle = DateFormatter.Style.short
            
            if let reminderDate : Date = dateFormatter.date(from: reminder.notes!) {
                
                if let shoppingCartExpiryTime : Date = defaults.object(forKey: Constants.ClearShoppingListExpire) as? Date {
                    
                    let shoppingCartExpiryTime : DateComponents =  NSDateManager.getDateComponentsFromDate(shoppingCartExpiryTime)
                    
                    let expiryTime : Date = NSDateManager.addHoursAndMinutesToDate(reminderDate, hours: shoppingCartExpiryTime.hour!, Minutes: shoppingCartExpiryTime.minute!)
                    
                    return NSDateManager.dateIsBeforeDate(expiryTime, date2: Date())
                }
                else {
                    
                    return true
                }
            }
        }
        
        return false
    }
}
