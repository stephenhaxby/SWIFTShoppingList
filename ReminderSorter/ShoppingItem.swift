//
//  ShoppingItem.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 3/4/17.
//  Copyright © 2017 Stephen Haxby. All rights reserved.
//

import Foundation
import CoreData

class ShoppingItem {
    
    var shoppingItem : NSManagedObject

    var id : String {
        
        get {
            
            return shoppingItem.value(forKey: "id") as! String
        }
        set (value) {
            
            shoppingItem.setValue(value, forKeyPath: "id")
        }
    }
    
    var title : String {
        
        get {
            
            return shoppingItem.value(forKey: "title") as! String
        }
        set (value) {
            
            shoppingItem.setValue(value, forKeyPath: "title")
        }
    }
    
    var completed : Bool {
        
        get {
            
            return shoppingItem.value(forKey: "completed") as! Bool
        }
        set (value) {
            
            shoppingItem.setValue(value, forKeyPath: "completed")
        }
    }
    
    var notes : String? {
        
        get {
            
            return shoppingItem.value(forKey: "notes") as? String
        }
        set (value) {
            
            shoppingItem.setValue(value, forKeyPath: "notes")
        }
    }
    
    init(managedObject : NSManagedObject) {
        
        self.shoppingItem = managedObject
    }
}
