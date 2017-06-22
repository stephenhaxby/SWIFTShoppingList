//
//  ShoppingListItem.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 25/01/2016.
//  Copyright © 2016 Stephen Haxby. All rights reserved.
//

import Foundation

class ShoppingListItem : Equatable, Hashable {
    
    var calendarItemExternalIdentifier : String = String()
    
    var title : String = String()
    
    var completed : Bool = true
    
    var notes : String?
    
    var hashValue: Int {
        return calendarItemExternalIdentifier.hashValue
    }
    
    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        return
            lhs.calendarItemExternalIdentifier == rhs.calendarItemExternalIdentifier
    }
}
