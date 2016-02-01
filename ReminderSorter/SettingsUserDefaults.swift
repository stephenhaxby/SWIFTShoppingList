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
        return NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortIncomplete")
    }
    
    static var alphabeticalSortComplete: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortComplete")
    }
    
    static var autoCapitalisation: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("autoCapitalisation")
    }
    
    static var disableScreenLock: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("disableScreenLock")
    }
}