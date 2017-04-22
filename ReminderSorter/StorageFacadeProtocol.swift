//
//  StorageFacadeProtocol.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 5/01/2016.
//  Copyright © 2016 Stephen Haxby. All rights reserved.
//

import Foundation

protocol StorageFacadeProtocol {
    
    func createOrUpdateShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ())
    
    func removeShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ())
    
    func removeShoppingListItem(_ Id : String, saveSuccess : @escaping (Bool) -> ())
    
    //Expects a function that has a parameter that's an array of ShoppingListItem
    func getShoppingListItems(_ returnShoppingListItems : @escaping ([ShoppingListItem]) -> ())
    
    func forceUpdateShoppingList()
    
    func commit() -> Bool
}
