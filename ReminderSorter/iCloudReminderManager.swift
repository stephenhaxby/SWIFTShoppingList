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
    var remindersListName = "Reminders"
    var reminderList : EKCalendar?
    
    //Requests access to reminders. Takes in a function to find if access has been granted or not.
    //We can then perform some action like stop a refresh control...
    func requestAccessToReminders(accessStatus : Bool -> ()){
        
        if(!eventStoreAccessGranted){
            
            //Request access to the users Reminders
            eventStore.requestAccessToEntityType(EKEntityType.Reminder, completion: {
                granted, error in
                
                //Save the 'granted' value - if we were granted access
                self.eventStoreAccessGranted = granted
                
                self.getReminderList()
                
                accessStatus(granted)
            })
        }
    }
    
    //Return our specified reminders list (by name = remindersListName)
    func getReminderList() -> EKCalendar?{
        
        if(eventStoreAccessGranted){
            
            if(reminderList == nil){
  
                //Create a new calendar as we can't set this to nil... We'll set it below
                //var shoppingListCalendar = EKCalendar(forEntityType: EKEntityTypeReminder, eventStore: eventStore)
                
                //Get the Reminders
                let calendars = eventStore.calendarsForEntityType(EKEntityType.Reminder) 
                
                var reminderListCalendars = calendars.filter({(calendar : EKCalendar) in calendar.title == self.remindersListName})
                
                if(reminderListCalendars.count == 1){
                    
                    reminderList = reminderListCalendars[0];
                }
                else if(reminderListCalendars.count > 1){
                    
                    return nil
                }
                else{
                    reminderList = EKCalendar(forEntityType: EKEntityType.Reminder, eventStore: eventStore)
                    
                    //Save the new calendar
                    reminderList!.title = remindersListName;
                    reminderList!.source = eventStore.defaultCalendarForNewReminders().source
                    
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
    
    func getReminders(returnReminders : [EKReminder] -> ()){
        
        var remindersList = [EKReminder]()
        
        if(eventStoreAccessGranted){
            
            let singlecallendarArrayForPredicate : [EKCalendar] = [reminderList!]
            let predicate = eventStore.predicateForRemindersInCalendars(singlecallendarArrayForPredicate)
            
            //Get all the reminders for the above search predicate
            eventStore.fetchRemindersMatchingPredicate(predicate) { reminders in
                
                if let matchingReminders = reminders {
                    
                    //For each reminder in iCloud
                    for reminder in matchingReminders {
                        
                        remindersList.append(reminder)
                    }
                }
                
                returnReminders(remindersList)
            }
        }
    }
    
    func addReminder(title : String) -> EKReminder?{
        
        let calendar : EKCalendar? = getReminderList()
        
        guard calendar != nil else {
            
            return nil
        }
        
        let reminder:EKReminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = calendar!
        
        do {
            
            try eventStore.saveReminder(reminder, commit: true)
            
        } catch _ as NSError {

            return nil
        }
        
        return reminder
    }
    
    func saveReminder(reminder : EKReminder) -> Bool{
        
        do {
            
            try eventStore.saveReminder(reminder, commit: true)
            
            return true
            
        } catch _ {
            
            return false
        }
    }
    
    func removeReminder(reminder : EKReminder) -> Bool{
        
        do {

            try eventStore.removeReminder(reminder, commit: true)
            
            return true
            
        } catch _ {
            
            return false
        }
    }
    
    func getNewReminder() -> EKReminder?{
        
        if reminderList != nil
        {
            let reminder : EKReminder = EKReminder(eventStore: eventStore)
            reminder.calendar = reminderList!
            
            return reminder
        }
        
        return nil
    }
}