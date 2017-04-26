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

        // TODO: Callback method from icloudReminderManager.requestAccessToReminders for if access is granted...
        // Something will need to happen with this as we can't load the list until access is granted
    }
    
    func createOrUpdateShoppingListItem(_ shoppingListItem : ShoppingListItem, saveSuccess : @escaping (Bool) -> ()) {
       
        icloudReminderManager.getReminder(shoppingListItem.calendarItemExternalIdentifier) {
            reminder in
            
            var reminderToSave : EKReminder?
            
            // Existing shopping list item
            if let matchingReminder : EKReminder = reminder {
                
                reminderToSave = matchingReminder
            }
            else {
                
                if let newReminder = self.icloudReminderManager.addReminder(shoppingListItem.title) {
                    
                    shoppingListItem.calendarItemExternalIdentifier = newReminder.calendarItemExternalIdentifier
                    reminderToSave = newReminder
                }
            }
            
            if let matchingReminder : EKReminder = reminderToSave {
                
                matchingReminder.title = shoppingListItem.title
                matchingReminder.isCompleted = shoppingListItem.completed
                matchingReminder.notes = shoppingListItem.notes
                
                saveSuccess(self.icloudReminderManager.saveReminder(matchingReminder))
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
}





