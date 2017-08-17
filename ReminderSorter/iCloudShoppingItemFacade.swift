//
//  iCloudReminderFacade.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 5/01/2016.
//  Copyright © 2016 Stephen Haxby. All rights reserved.
//

import Foundation
import EventKit

class iCloudShoppingItemFacade : StorageFacadeProtocol {
    
    var icloudReminderManager : iCloudReminderManager! = nil

    var returnRemindersFunc : (([ShoppingListItem]) -> ())?

    init (icloudReminderManager : iCloudReminderManager) {

        self.icloudReminderManager = icloudReminderManager

        // Set the name of the reminder list we are going to use
        self.icloudReminderManager.remindersListName = Constants.RemindersListName

        // Request access to Reminders
        self.icloudReminderManager.requestAccessToReminders(accessGranted)
    }

    func accessGranted(_ granted : Bool) {

        if !granted {
            
            SettingsUserDefaults.storageICloudReminders = false
        }
    }
    
    func createOrUpdateShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ()) {
       
        icloudReminderManager.getReminder(shoppingListItem.calendarItemExternalIdentifier) {
            reminder in
            
            var isNewReminder = false
            
            var reminderToSave : EKReminder?
            
            // Existing shopping list item
            if let matchingReminder : EKReminder = reminder {
                
                reminderToSave = matchingReminder
            }
            else {
                
                if let newReminder = self.icloudReminderManager.addReminder(shoppingListItem.title) {
                    
                    isNewReminder = true
                    
                    shoppingListItem.calendarItemExternalIdentifier = newReminder.calendarItemExternalIdentifier
                    reminderToSave = newReminder
                }
            }
            
            if let matchingReminder : EKReminder = reminderToSave {
                
                matchingReminder.title = shoppingListItem.title
                matchingReminder.isCompleted = shoppingListItem.completed
                matchingReminder.notes = shoppingListItem.notes
                
                saveSuccess(self.icloudReminderManager.saveReminder(matchingReminder, commit: isNewReminder))
            }
        }
    }
    
    func removeShoppingListItem(_ Id : String, saveSuccess : @escaping (Bool) -> ()) {
        
        icloudReminderManager.getReminder(Id) {
            reminder in
            
            if let matchingReminder : EKReminder = reminder {
                
                saveSuccess(self.icloudReminderManager.removeReminder(matchingReminder))
            }
        }
    }

    func removeShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ()) {

        removeShoppingListItem(shoppingListItem.calendarItemExternalIdentifier, saveSuccess: saveSuccess)
    }

    //Expects a function that has a parameter that's an array of RemindMeItem
    func getShoppingListItems(_ returnReminders : @escaping ([ShoppingListItem]) -> ()){

        returnRemindersFunc = returnReminders

        icloudReminderManager.getReminders(getiCloudReminders)
    }

    fileprivate func getiCloudReminders(_ iCloudShoppingList : [EKReminder]){

        returnRemindersFunc!(iCloudShoppingList.map({

            (reminder : EKReminder) -> ShoppingListItem in

            return getShoppingListItemFrom(reminder)
        }))
    }

    func forceUpdateShoppingList() {

        icloudReminderManager.forceUpdateShoppingList()
    }
    
    func commit() -> Bool {

        return icloudReminderManager.commit()
    }

    func getShoppingListItemFrom(_ reminder : EKReminder) -> ShoppingListItem {

        let shoppingListItem : ShoppingListItem = ShoppingListItem()

        shoppingListItem.calendarItemExternalIdentifier = reminder.calendarItemExternalIdentifier
        shoppingListItem.title = reminder.title
        shoppingListItem.completed = reminder.isCompleted
        shoppingListItem.notes = reminder.notes

        return shoppingListItem
    }
    
    func clearShoppingList(complete : @escaping (Bool) -> ()){

        icloudReminderManager.getReminders() {
            shoppingList in
            
            var saveSuccess = true
            
            let shoppingCartItems : [EKReminder] = shoppingList.filter({(reminder : EKReminder) in Utility.itemIsInShoppingCart(self.getShoppingListItemFrom(reminder))})
    
            for shoppingCartItem in shoppingCartItems {
    
                let shoppingCartItemNotes : String = ((Utility.getDateFromNotes(shoppingCartItem.notes) == nil) ? Utility.getDateForNotes() : shoppingCartItem.notes!)
                
                shoppingCartItem.notes = "*" + shoppingCartItemNotes

                if !self.icloudReminderManager.saveReminder(shoppingCartItem, commit: false) {
                    
                    saveSuccess = false
                }
            }
            
            complete(saveSuccess)
        }
    }
}





