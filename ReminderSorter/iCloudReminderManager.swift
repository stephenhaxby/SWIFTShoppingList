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
            eventStore.requestAccessToEntityType(EKEntityTypeReminder, completion: {
                granted, error in
                
                //Save the 'granted' value - if we were granted access
                self.eventStoreAccessGranted = granted
                
                if(granted)
                {
                    //For some reason we need to call this in this method, otherwise we get errors the first time it's ran...
                    let calendars : [EKCalendar] = self.eventStore.calendarsForEntityType(EKEntityTypeReminder) as! [EKCalendar]
                }
                
                self.getReminderList()
                
                accessStatus(granted)
            })
        }
    }
    
    //Return our specified reminders list (by name = remindersListName)
    func getReminderList() -> EKCalendar{
        
        if(eventStoreAccessGranted){
            
            if(reminderList == nil){
  
                //Create a new calendar as we can't set this to nil... We'll set it below
                //var shoppingListCalendar = EKCalendar(forEntityType: EKEntityTypeReminder, eventStore: eventStore)
                
                //Get the Reminders
                var calendars = eventStore.calendarsForEntityType(EKEntityTypeReminder) as! [EKCalendar]
                
                var reminderListCalendars = calendars.filter({(calendar : EKCalendar) in calendar.title == self.remindersListName})
                
                if(reminderListCalendars.count == 1){
                    
                    reminderList = reminderListCalendars[0];
                }
                else if(reminderListCalendars.count > 1){
                    //TODO: Print error
                }
                else{
                    reminderList = EKCalendar(forEntityType: EKEntityTypeReminder, eventStore: eventStore)
                    
                    //Save the new calendar
                    reminderList!.title = remindersListName;
                    reminderList!.source = eventStore.defaultCalendarForNewReminders().source
                    
                    var error: NSError?
                    eventStore.saveCalendar(reminderList!, commit: true, error: &error)
                    
                    //TODO: What to do if this fails...
                }
            }
            
            //TODO: This will error if count > 1 or the calendar couldn't save
            return reminderList!
        }
        
        //TODO: This will cause huge problems if access is NOT granted!
        return EKCalendar(forEntityType: EKEntityTypeReminder, eventStore: eventStore)
    }
    
    func getReminders(returnReminders : [EKReminder] -> ()){
        
        var remindersList = [EKReminder]()
        
        if(eventStoreAccessGranted){
            
            var singlecallendarArrayForPredicate : [EKCalendar] = [reminderList!]
            var predicate = eventStore.predicateForRemindersInCalendars(singlecallendarArrayForPredicate)
            
            //Get all the reminders for the above search predicate
            eventStore.fetchRemindersMatchingPredicate(predicate) { reminders in
                
                //For each reminder in iCloud
                for reminder in reminders {
                    
                    remindersList.append(reminder as! EKReminder)
                }
                
                returnReminders(remindersList)
            }
        }
    }
    
    func addReminder(title : String) -> EKReminder{
        
        var error: NSError?
        
        var reminder:EKReminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = getReminderList()
        
        eventStore.saveReminder(reminder, commit: true, error: &error)
        
        return reminder
    }
    
    func saveReminder(reminder : EKReminder) -> Bool{
        
        var error: NSError?
        return eventStore.saveReminder(reminder, commit: true, error: &error)
    }
    
    func removeReminder(reminder : EKReminder) -> Bool{
        
        var error: NSError?
        
        //TODO: What to do when eventStore is nil or this errors
        return eventStore.removeReminder(reminder, commit: true, error: &error)
    }
    
    func getNewReminder() -> EKReminder{
        
        //Create a new reminder using the 'title' of the old one.
        var reminder : EKReminder = EKReminder(eventStore: eventStore)
        reminder.calendar = reminderList
        
        return reminder
    }
}