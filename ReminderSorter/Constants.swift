//
//  ShoppingListItemConstants.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 17/11/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import Foundation
import UIKit

class Constants{

    struct ShoppingListItemTableViewCell {
        
        static let EmptyCell:String = "<EMPTY_CELL>"
        
        static let NewItemCell:String = "<NEW_ITEM_CELL>"
    }
    
    static let QuickScrollButtonPressed:String = "QuickScrollButtonPressed"
    
    static let RemindersListName:String = "Shopping"
    
    static let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    static let SaveReminder : String = "SaveReminder"
    
    static let ClearShoppingList : String = "ClearShoppingList"
    
    static let ClearShoppingListExpire : String = "ClearShoppingListExpire"
    
    static let SetClearShoppingList : String = "SetClearShoppingList"
    
    static let ClearShoppingListOnOpen : String = "ClearShoppingListOnOpen"
    
    static let SearchBarTextDidChange : String = "SearchBarTextDidChange"
    
    static let SearchBarCancel : String = "SearchBarCancel"
    
    static let SetRefreshLock : String = "SetRefreshLock"
    
    static let InactiveLock : String = "InactiveLock"
    
    static let ActionOnLocked : String = "ActionOnLocked"

    static let ItemEditing : String = "ItemEditing"   
    
    static let ShoppingListSections = 3
    
    static let ShoppingListItemFont = UIFont(name: "American Typewriter", size: 21.0)!
    
    static let QuickJumpListItemFont = UIFont(name: "American Typewriter", size: 14.0)!
    
    static let SettingUserDefaultAlphabeticalSortIncomplete = "alphabeticalSortIncomplete"
    
    static let SettingUserDefaultAlphabeticalSortComplete = "alphabeticalSortComplete"
    
    static let SettingUserDefaultAutoCapitalisation = "autoCapitalisation"
    
    static let SettingUserDefaultDisableScreenLock = "disableScreenLock"
    
    static let SettingUserDefaultSearchBeginsWith = "searchBeginsWith"
    
    static let SettingUserDefaultAutoLockList = "autoLockList"
    
    enum ShoppingListSection : Int, CustomStringConvertible {
        case List
        case Cart
        case History
        
        var description: String {
            
            switch self {
            
                case List: return "Shopping List"
            
                case Cart: return "Trolley"
                
                case History: return "History"
                
            }
        }
    }
}
