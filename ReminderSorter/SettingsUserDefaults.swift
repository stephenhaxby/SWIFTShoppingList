//
//  SettingsUserDefaults.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 17/11/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import Foundation

class SettingsUserDefaults{
    
    static var trolleySorting: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultTrolleySorting)
            ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultTrolleySorting)
            : false
    }
    
    static var autoCapitalisation: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultAutoCapitalisation)
            ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultAutoCapitalisation)
            : true
    }
    
    static var disableScreenLock: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultDisableScreenLock)
            ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultDisableScreenLock)
            : true
    }
    
    static var searchBeginsWith: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultSearchBeginsWith)
            ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultSearchBeginsWith)
            : true
    }
    
    static var autoLockList: Bool {
        
        return hasDefaultValue(Constants.SettingUserDefaultAutoLockList)
            ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultAutoLockList)
            : false
    }
    
    static var storageICloudReminders: Bool {
        
        set {
            
            UserDefaults.standard.set(newValue, forKey: Constants.SettingUserDefaultStorageICloudReminders)
        }
        
        get {
            
            return hasDefaultValue(Constants.SettingUserDefaultStorageICloudReminders)
                ? UserDefaults.standard.bool(forKey: Constants.SettingUserDefaultStorageICloudReminders)
                : false
        }
    }
    
    
    
    static func hasDefaultValue(_ key: String) -> Bool {
        
        return UserDefaults.standard.value(forKey: key) != nil
    }
}
