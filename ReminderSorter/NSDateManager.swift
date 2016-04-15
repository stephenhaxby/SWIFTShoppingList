//
//  NSDateManager.swift
//  RemindMe
//
//  Created by Stephen Haxby on 7/12/2015.
//  Copyright � 2015 Stephen Haxby. All rights reserved.
//

import Foundation

class NSDateManager {
    
    static func dateWithDay(day : Int, month : Int, year : Int) -> NSDate {
        
        let dateComponents : NSDateComponents = NSDateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        return getDateFromComponents(dateComponents)
    }
    
    static func dateWithDay(day : Int, month : Int, year : Int, hour : Int, minute : Int, second : Int) -> NSDate {
        
        let dateComponents : NSDateComponents = NSDateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        return getDateFromComponents(dateComponents)
    }
    
    static func dateIsEqualToDate(date1 : NSDate, date2 : NSDate) -> Bool {
    
        let date1Components : NSDateComponents = getDateComponentsFromDate(date1)
        let date2Components : NSDateComponents = getDateComponentsFromDate(date2)
        
        return (date1Components.year == date2Components.year
            && date1Components.month == date2Components.month
            && date1Components.day == date2Components.day)
    }
    
    static func timeIsEqualToTime(date1 : NSDate, date2 : NSDate) -> Bool {
        
        let date1Components : NSDateComponents = getDateComponentsFromDate(date1)
        let date2Components : NSDateComponents = getDateComponentsFromDate(date2)
        
        return (date1Components.hour == date2Components.hour
            && date1Components.minute == date2Components.minute
            && date1Components.second == date2Components.second)
    }
    
    static func timeIsEqualToTime(date1 : NSDate, date2Components : NSDateComponents) -> Bool {
        
        let date1Components : NSDateComponents = getDateComponentsFromDate(date1)
        let date2CompnentsPassThrough = date2Components
        
        return timeIsEqualToTime(date1Components, date2Components: date2CompnentsPassThrough)
    }
    
    static func timeIsEqualToTime(date1Components : NSDateComponents, date2Components : NSDateComponents) -> Bool {
        
        return (date1Components.hour == date2Components.hour
            && date1Components.minute == date2Components.minute
            && date1Components.second == date2Components.second)
    }
    
    static func dateTimeIsEqualToDateTime(date1 : NSDate, date2 : NSDate) -> Bool {
    
        return dateIsEqualToDate(date1, date2: date2) && timeIsEqualToTime(date1, date2: date2)
    }
    
    static func addDaysToDate(date : NSDate, days : Int) -> NSDate {

        let dateComponents : NSDateComponents = NSDateComponents()
        dateComponents.day = days;

        let calendar = NSCalendar.currentCalendar()         
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate : date, options: NSCalendarOptions(rawValue: 0))
        
        //TODO: Error handling
        return newDate!
    }
    
    static func addHoursAndMinutesToDate(date : NSDate, hours : Int, Minutes : Int) -> NSDate {
        
        let dateComponents : NSDateComponents = NSDateComponents()
        dateComponents.hour = hours
        dateComponents.minute = Minutes
        
        let calendar = NSCalendar.currentCalendar()
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate : date, options: NSCalendarOptions(rawValue: 0))
        
        //TODO: Error handling
        return newDate!
    }
    
    static func subtractDaysFromDate(date : NSDate, days : Int) -> NSDate {
    
        return addDaysToDate(date, days : (days - (days * 2)))
    }
    
    static func currentDateWithHour(hour : Int, minute : Int, second : Int) -> NSDate {
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        
        let dateComponents : NSDateComponents = NSDateComponents()
        dateComponents.year = calendar.component(NSCalendarUnit.Year, fromDate: date)
        dateComponents.month = calendar.component(NSCalendarUnit.Month, fromDate: date)
        dateComponents.day = calendar.component(NSCalendarUnit.Day, fromDate: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        
        return getDateFromComponents(dateComponents)
    }
    
    static func dateStringFromComponents(dateComponents : NSDateComponents) -> String {
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        
        let currentDateComponents : NSDateComponents = NSDateComponents()
        
        currentDateComponents.calendar = calendar
        currentDateComponents.year = calendar.component(NSCalendarUnit.Year, fromDate: date)
        currentDateComponents.month = calendar.component(NSCalendarUnit.Month, fromDate: date)
        currentDateComponents.day = calendar.component(NSCalendarUnit.Day, fromDate: date)
        currentDateComponents.hour = dateComponents.hour
        currentDateComponents.minute = dateComponents.minute
        currentDateComponents.second = dateComponents.second
        
        let currentDate : NSDate? = currentDateComponents.date
        let dateComponentsDate : NSDate? = dateComponents.date
        
        let dateCompareResult = currentDate!.compare(dateComponentsDate!)
        
        let displayHour = (dateComponents.hour > 12) ? dateComponents.hour-12 : dateComponents.hour
        let displayMinute = (dateComponents.minute < 10) ? "0\(dateComponents.minute)" : String(dateComponents.minute)
        let displayAMPM = (dateComponents.hour > 12) ? "PM" : "AM"
        
        let timeString : String = "\(displayHour):\(displayMinute) \(displayAMPM)"
        
        var dateString : String
        
        switch dateCompareResult {
            
        case NSComparisonResult.OrderedSame:
            dateString = "Today, \(timeString)"
            break
        case NSComparisonResult.OrderedDescending:
            
            if dateComponents.year == currentDateComponents.year
                && dateComponents.year == currentDateComponents.year
                && dateComponents.day == currentDateComponents.day-1 {
                
                dateString = "Yesterday, \(timeString)"
            }
            else {
                
                dateString = "\(dateComponents.day)/\(dateComponents.month)/\(dateComponents.year), \(timeString)"
            }
            break
        case NSComparisonResult.OrderedAscending:
            dateString = "Tomorrow, \(timeString)"
            break
        }
        
        return dateString
    }
    
    static func dateIsBeforeDate(date1 : NSDate, date2 : NSDate) -> Bool {
        
        let dateCompareResult = date1.compare(date2)
        
        return dateCompareResult == NSComparisonResult.OrderedDescending
    }
    
    static func dateIsAfterDate(date1 : NSDate, date2 : NSDate) -> Bool {
        
        let dateCompareResult = date1.compare(date2)
        
        return dateCompareResult == NSComparisonResult.OrderedAscending
    }
    
    static func getDateFromComponents(components : NSDateComponents) -> NSDate {
        
        let gregorian = NSCalendar(identifier:NSCalendarIdentifierGregorian)
        let date = gregorian!.dateFromComponents(components)
        
        return date!
    }
    
    static func getDateComponentsFromDate(date : NSDate) -> NSDateComponents {
    
        let calendar = NSCalendar.currentCalendar()
        let dateComponents : NSDateComponents = NSDateComponents()
        
        dateComponents.calendar = calendar
        dateComponents.year = calendar.component(NSCalendarUnit.Year, fromDate: date)
        dateComponents.month = calendar.component(NSCalendarUnit.Month, fromDate: date)
        dateComponents.day = calendar.component(NSCalendarUnit.Day, fromDate: date)
        dateComponents.hour = calendar.component(NSCalendarUnit.Hour, fromDate: date)
        dateComponents.minute = calendar.component(NSCalendarUnit.Minute, fromDate: date)
        dateComponents.second = calendar.component(NSCalendarUnit.Second, fromDate: date)

        return dateComponents;
    }
}