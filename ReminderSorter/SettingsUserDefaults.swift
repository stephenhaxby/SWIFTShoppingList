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
        
        return hasDefaultValue(Constants.SettingUserDefaultAlphabeticalSortIncomplete)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultAlphabeticalSortIncomplete)
            : true
    }
    
    static var alphabeticalSortComplete: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultAlphabeticalSortComplete)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultAlphabeticalSortComplete)
            : true
    }
    
    static var autoCapitalisation: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultAutoCapitalisation)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultAutoCapitalisation)
            : true
    }
    
    static var disableScreenLock: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultDisableScreenLock)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultDisableScreenLock)
            : true
    }
    
    static var searchBeginsWith: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultSearchBeginsWith)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultSearchBeginsWith)
            : true
    }
    
    static var autoLockList: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultAutoLockList)
            ? NSUserDefaults.standardUserDefaults().boolForKey(Constants.SettingUserDefaultAutoLockList)
            : false
    }
    
    static func hasDefaultValue(key: String) -> Bool {
        
        return NSUserDefaults.standardUserDefaults().valueForKey(key) != nil
    }
}