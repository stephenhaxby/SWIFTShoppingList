//
//  ShoppingListItemFacade.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 3/4/17.
//  Copyright © 2017 Stephen Haxby. All rights reserved.
//

import Foundation

class ShoppingItemFacade : StorageFacadeProtocol {
    
    var shoppingItemRepository : ShoppingItemRepository
    
    init (shoppingItemRepository : ShoppingItemRepository) {
        
        self.shoppingItemRepository = shoppingItemRepository
    }

    func createOrUpdateShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ()) {
        
        if let shoppingItem : ShoppingItem = shoppingItemRepository.getShoppingItemBy(shoppingListItem.calendarItemExternalIdentifier) {
            
            shoppingItem.title = shoppingListItem.title
            shoppingItem.completed = shoppingListItem.completed
            shoppingItem.notes = shoppingListItem.notes
        }
        else {
            
            let _ = shoppingItemRepository.createNewShoppingItem(
                shoppingListItem.title,
                completed : shoppingListItem.completed,
                notes : shoppingListItem.notes)
        }
    }
    
    func forceUpdateShoppingList() {
        
    }
    
    func removeShoppingListItem(_ Id: String, saveSuccess : @escaping (Bool) -> ()){
        
        saveSuccess(shoppingItemRepository.removeShoppingItem(Id))
    }
    
    func removeShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ()) {
        
        if let shoppingItem : ShoppingItem = shoppingItemRepository.getShoppingItemBy(shoppingListItem.calendarItemExternalIdentifier) {
            
            saveSuccess(shoppingItemRepository.removeShoppingItem(shoppingItem))
        }
        
        saveSuccess(false)
    }
    
    //Expects a function that has a parameter that's an array of RemindMeItem
    func getShoppingListItems(_ returnShoppingItems : @escaping ([ShoppingListItem]) -> ()){
        
        returnShoppingItems(shoppingItemRepository.getShoppingItems().map({
            
            (shoppingItem : ShoppingItem) -> ShoppingListItem in
            
            return getShoppingItemFrom(shoppingItem)
        }))
    }
    
    func commit() -> Bool {
        
        return shoppingItemRepository.commit()
    }
    
    func getShoppingItemFrom(_ shoppingItem : ShoppingItem) -> ShoppingListItem {
        
        let shoppingListItem = ShoppingListItem()
        shoppingListItem.calendarItemExternalIdentifier = shoppingItem.id!
        shoppingListItem.title = shoppingItem.title!
        shoppingListItem.completed = shoppingItem.completed
        shoppingListItem.notes = shoppingItem.notes
        
        return shoppingListItem
    }
}






