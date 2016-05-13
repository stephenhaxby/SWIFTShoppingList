//
//  SettingsUserDefaults.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 17/11/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import Foundation

class SettingsUserDefaults{
    
    static var alphabeticalSortIncomplete: Bool {
        
        if NSUserDefaults.standardUserDefaults().dataForKey("alphabeticalSortIncomplete") != nil {
            
            return true
        }
        
        return NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortIncomplete")
    }
    
    static var alphabeticalSortComplete: Bool {
        
        if NSUserDefaults.standardUserDefaults().dataForKey("alphabeticalSortComplete") != nil {
            
            return true
        }
        
        return NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortComplete")
    }
    
    static var autoCapitalisation: Bool {
        
        if NSUserDefaults.standardUserDefaults().dataForKey("autoCapitalisation") != nil {
            
            return true
        }
        
        return NSUserDefaults.standardUserDefaults().boolForKey("autoCapitalisation")
    }
    
    static var disableScreenLock: Bool {
        
        if NSUserDefaults.standardUserDefaults().dataForKey("disableScreenLock") != nil {
            
            return true
        }
        
        return NSUserDefaults.standardUserDefaults().boolForKey("disableScreenLock")
    }
}