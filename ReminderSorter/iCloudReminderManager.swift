//
//  iCloudReminderManager.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 3/09/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import EventKit

class iCloudReminderManager{
    
    var eventStoreAccessGranted = false
    let eventStore = EKEventStore()
    var remindersListName = Constants.RemindersListName
    var reminderList : EKCalendar?
    
    //Requests access to reminders. Takes in a function to find if access has been granted or not.
    //We can then perform some action like stop a refresh control...
    func requestAccessToReminders(_ accessStatus : @escaping (Bool) -> ()){
        
        if(!eventStoreAccessGranted){
            
            //Request access to the users Reminders
            eventStore.requestAccess(to: EKEntityType.reminder, completion: {
                granted, error in
                
                //Save the 'granted' value - if we were granted access
                self.eventStoreAccessGranted = granted
                
                //Setup the Shopping Calendar
                let _ = self.getReminderList()
                
                accessStatus(granted)
            })
        }
    }
    
    func getReminder(_ id : String, returnReminder : @escaping (EKReminder?) -> ()) {

        var remindersList = [EKReminder]()

        if(eventStoreAccessGranted && reminderList != nil){

            let singlecallendarArrayForPredicate : [EKCalendar] = [reminderList!]
            let predicate = eventStore.predicateForReminders(in: singlecallendarArrayForPredicate)

            eventStore.fetchReminders(matching: predicate) { reminders in

                if let matchingReminders = reminders {

                    //For each reminder in iCloud
                    for reminder in matchingReminders {

                        remindersList.append(reminder)
                    }
                }

                var foundReminder : EKReminder?

                if let index = remindersList.index(where: { (reminder : EKReminder) in reminder.calendarItemExternalIdentifier == id}) {

                    foundReminder = remindersList[index]
                }
                
                returnReminder(foundReminder)
            }
        }
    }
    
    func forceUpdateShoppingList() {

        if let reminder : EKReminder = addReminder(Constants.ShoppingListItemTableViewCell.iCloudRefreshHelperCell) {
            
            if removeReminder(reminder) {
                
                let _ = commit()
            }
        }
    }
    
    //Return our specified reminders list (by name = remindersListName)
    func getReminderList() -> EKCalendar?{
        
        if(eventStoreAccessGranted){
            
            if(reminderList == nil){
  
                //Create a new calendar as we can't set this to nil... We'll set it below
                //var shoppingListCalendar = EKCalendar(forEntityType: EKEntityTypeReminder, eventStore: eventStore)
                
                //Get the Reminders
                let calendars = eventStore.calendars(for: EKEntityType.reminder) 
                
                var reminderListCalendars = calendars.filter({(calendar : EKCalendar) in calendar.title == self.remindersListName})
                
                if(reminderListCalendars.count == 1) {
                    
                    reminderList = reminderListCalendars[0];
                }
                else if(reminderListCalendars.count > 1) {
                    
                    return nil
                }
                else {
                    
                    reminderList = EKCalendar(for: EKEntityType.reminder, eventStore: eventStore)
                    
                    //Save the new calendar
                    reminderList!.title = remindersListName;
                    reminderList!.source = eventStore.defaultCalendarForNewReminders()?.source
                    
                    do {
                        
                        try eventStore.saveCalendar(reminderList!, commit: true)
                        
                    } catch _ as NSError {
                      
                        return nil
                    }
                }
            }
            
            return reminderList
        }
        
        return nil
    }
    
    func getReminders(_ returnReminders : @escaping ([EKReminder]) -> ()){
        
        var remindersList = [EKReminder]()
        
        if(eventStoreAccessGranted && reminderList != nil){
            
            let singlecallendarArrayForPredicate : [EKCalendar] = [reminderList!]
            let predicate = eventStore.predicateForReminders(in: singlecallendarArrayForPredicate)
            
            //Get all the reminders for the above search predicate
            eventStore.fetchReminders(matching: predicate) { reminders in
                
                if let matchingReminders = reminders {
                    
                    //For each reminder in iCloud
                    for reminder in matchingReminders {
                        
                        remindersList.append(reminder)
                    }
                    
                    returnReminders(remindersList)
                }
            }
        }
    }
    
    func addReminder(_ title : String) -> EKReminder? {
        
        let calendar : EKCalendar? = getReminderList()
        
        guard calendar != nil else {
            
            return nil
        }
        
        let reminder:EKReminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = calendar!
        
        do {
            
            try eventStore.save(reminder, commit: false)
            
        } catch {

            return nil
        }
        
        return reminder
    }
    
    func saveReminder(_ reminder : EKReminder, commit : Bool) -> Bool{
        
        do {
            
            try eventStore.save(reminder, commit: commit)
            
        } catch let error as NSError {
            
            //That event does not belong to that event store (error.code == 11).
            guard error.code == 11 else {
                
                return false
            }
        }
        
        return true
    }
    
    func removeReminder(_ reminder : EKReminder) -> Bool {
        
        do {

            try eventStore.remove(reminder, commit: false)
            
            return true
            
        } catch {
            
            return false
        }
    }
    
    func getNewReminder() -> EKReminder? {
        
        if reminderList != nil
        {
            let reminder : EKReminder = EKReminder(eventStore: eventStore)
            reminder.calendar = reminderList!
            
            return reminder
        }
        
        return nil
    }
    
    func commit() -> Bool {
        
        do {
            
            try eventStore.commit()
            
            return true
        }
        catch {
            
            return false
        }
    }
    
    func saveCalendar() -> Bool {
        
        if reminderList != nil {
            
            do {
            
                try eventStore.saveCalendar(reminderList!, commit: true)
            
                return true
            }
            catch {

                return false
            }
        }
        
        return false
    }
}
