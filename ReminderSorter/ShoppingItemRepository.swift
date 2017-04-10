//
//  ShoppingItemRepository.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 3/4/17.
//  Copyright © 2017 Stephen Haxby. All rights reserved.
//

import Foundation
import CoreData

class ShoppingItemRepository {
    
    var managedObjectContext : NSManagedObjectContext
    
    init(managedObjectContext : NSManagedObjectContext){
        
        self.managedObjectContext = managedObjectContext
    }
    
    func createNewShoppingItem() -> ShoppingItem {
        
        let entity = NSEntityDescription.entity(forEntityName: "ShoppingItem", in:managedObjectContext)
        
        let shoppingItemManagedObject = NSManagedObject(entity: entity!, insertInto: managedObjectContext)
        
        return ShoppingItem(managedObject: shoppingItemManagedObject)
    }
    
    func createNewShoppingItem(_ title : String, completed : Bool, notes : String?) -> ShoppingItem {
        
        let shoppingItem : ShoppingItem = createNewShoppingItem()
        
        shoppingItem.id = UUID().uuidString
        shoppingItem.title = title
        shoppingItem.completed = completed
        shoppingItem.notes = notes
        
        return shoppingItem
    }
    
    func getShoppingItemBy(_ id : String) -> ShoppingItem? {
        
        var shoppingItemId = id
        
        //36 is the length of a GUID.
        //This is to cater for the setReminderNotification fix in LocationNotificationManager to cater for async methods
        if id.characters.count > 36 {
            
            let index = id.index(id.startIndex, offsetBy: 36)
            
            shoppingItemId = shoppingItemId.substring(to: index)
        }
        
        let shoppingItemFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ShoppingItem")
        
        shoppingItemFetch.predicate = NSPredicate(format: "id == %@", shoppingItemId)
        
        do {
            
            let shoppingItems : [ShoppingItem] = (try managedObjectContext.fetch(shoppingItemFetch) as! [NSManagedObject]).map({
                
                (managedObject : NSManagedObject) -> ShoppingItem in
                
                return ShoppingItem(managedObject: managedObject)
            })
            
            if shoppingItems.count == 1 {
                
                return shoppingItems.first!
            }
        }
        catch {
            
            fatalError("Failed to fetch shopping items: \(error)")
        }
        
        return nil
    }
    
    func getShoppingItems() -> [ShoppingItem] {
        
        do {
            
            return
                (try managedObjectContext.fetch(NSFetchRequest(entityName: "ShoppingItem")) ).map({
                    
                    (managedObject : NSManagedObject) -> ShoppingItem in
                    
                    return ShoppingItem(managedObject: managedObject)
                })
            
        }
        catch let error as NSError {
            
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return [ShoppingItem]()
    }
    
    func removeShoppingItem(_ Id : String) -> Bool {
        
        if let shoppingItem = getShoppingItemBy(Id) {
            
            return removeShoppingItem(shoppingItem)
        }
        
        return false
    }
    
    func removeShoppingItem(_ shoppingItem : ShoppingItem) -> Bool {
        
        managedObjectContext.delete(shoppingItem.shoppingItem)
        
        return true
    }
    
    func commit() -> Bool {
        
        do {
            
            if managedObjectContext.hasChanges {
                
                try managedObjectContext.save()
            }
            
        } catch let error as NSError  {
            
            print("Could not save \(error), \(error.userInfo)")
            
            return false
        }
        
        return true
    }
}

