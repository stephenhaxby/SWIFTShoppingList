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

    var eventStoreObserver : NSObjectProtocol?

    var icloudReminderManager : iCloudReminderManager! = nil

    var returnRemindersFunc : (([ShoppingListItem]) -> ())?

    init (icloudReminderManager : iCloudReminderManager) {

        // Sets the method to run when the Event Store is updated in the background
        eventStoreObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.EKEventStoreChanged, object: nil, queue: nil){
            (notification) -> Void in

            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.RefreshNotification), object: nil)
        }

        self.icloudReminderManager = icloudReminderManager

        // Set the name of the reminder list we are going to use
        self.icloudReminderManager.remindersListName = Constants.RemindersListName

        // Request access to Reminders
        self.icloudReminderManager.requestAccessToReminders(accessGranted)
    }

    func accessGranted(_ granted : Bool) {

        //TODO: Callback method from icloudReminderManager.requestAccessToReminders for if access is granted...
        // Perhaps call a NotificationCenter method that will set the save method to local reminders.?.?
    }
    
    func createOrUpdateShoppingListItem(_ shoppingListItem : ShoppingListItem) -> Bool {

        var reminderSaved : Bool = false
        
        icloudReminderManager.getReminder(shoppingListItem.calendarItemExternalIdentifier) {
            reminder in

            var reminderToSave : EKReminder?
            
            if let matchingReminder : EKReminder = reminder {
                
                reminderToSave = matchingReminder
            }
            else {
                
                if let newReminder = self.icloudReminderManager.addReminder(shoppingListItem.title, commit: true) {
                    
                    reminderToSave = newReminder
                }
            }
            
            if let matchingReminder : EKReminder = reminderToSave {
                
                matchingReminder.title = shoppingListItem.title
                matchingReminder.isCompleted = shoppingListItem.completed
                matchingReminder.notes = shoppingListItem.notes
                
                reminderSaved = self.icloudReminderManager.saveReminder(matchingReminder, commit: true)
            }
        }
        
        return reminderSaved
    }

    func removeShoppingListItem(_ Id : String) -> Bool {

        var reminderRemoved = false
        
        icloudReminderManager.getReminder(Id) {
            reminder in
            
            if let matchingReminder : EKReminder = reminder {
                
                reminderRemoved = self.icloudReminderManager.removeReminder(matchingReminder, commit: true)
                
            }
        }
        
        return reminderRemoved
    }

    func removeShoppingListItem(_ shoppingListItem : ShoppingListItem) -> Bool {

        return removeShoppingListItem(shoppingListItem.calendarItemExternalIdentifier)
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





