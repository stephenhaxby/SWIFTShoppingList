//
//  NSDateManager.swift
//  RemindMe
//
//  Created by Stephen Haxby on 7/12/2015.
//  Copyright � 2015 Stephen Haxby. All rights reserved.
//

import Foundation

class NSDateManager {
    
    static func dateWithDay(_ day : Int, month : Int, year : Int) -> Date {
        
        var dateComponents : DateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        return getDateFromComponents(dateComponents)
    }
    
    static func dateWithDay(_ day : Int, month : Int, year : Int, hour : Int, minute : Int, second : Int) -> Date {
        
        var dateComponents : DateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second

        return getDateFromComponents(dateComponents)
    }
    
    static func dateIsEqualToDate(_ date1 : Date, date2 : Date) -> Bool {
    
        let date1Components : DateComponents = getDateComponentsFromDate(date1)
        let date2Components : DateComponents = getDateComponentsFromDate(date2)
        
        return (date1Components.year == date2Components.year
            && date1Components.month == date2Components.month
            && date1Components.day == date2Components.day)
    }
    
    static func timeIsEqualToTime(_ date1 : Date, date2 : Date) -> Bool {
        
        let date1Components : DateComponents = getDateComponentsFromDate(date1)
        let date2Components : DateComponents = getDateComponentsFromDate(date2)
        
        return (date1Components.hour == date2Components.hour
            && date1Components.minute == date2Components.minute
            && date1Components.second == date2Components.second)
    }
    
    static func timeIsEqualToTime(_ date1 : Date, date2Components : DateComponents) -> Bool {
        
        let date1Components : DateComponents = getDateComponentsFromDate(date1)
        let date2CompnentsPassThrough = date2Components
        
        return timeIsEqualToTime(date1Components, date2Components: date2CompnentsPassThrough)
    }
    
    static func timeIsEqualToTime(_ date1Components : DateComponents, date2Components : DateComponents) -> Bool {
        
        return (date1Components.hour == date2Components.hour
            && date1Components.minute == date2Components.minute
            && date1Components.second == date2Components.second)
    }
    
    static func dateTimeIsEqualToDateTime(_ date1 : Date, date2 : Date) -> Bool {
    
        return dateIsEqualToDate(date1, date2: date2) && timeIsEqualToTime(date1, date2: date2)
    }
    
    static func addDaysToDate(_ date : Date, days : Int) -> Date {

        var dateComponents : DateComponents = DateComponents()
        dateComponents.day = days;

        let calendar = Calendar.current         
        let newDate = (calendar as NSCalendar).date(byAdding: dateComponents, to : date, options: NSCalendar.Options(rawValue: 0))
        
        //TODO: Error handling
        return newDate!
    }
    
    static func addHoursAndMinutesToDate(_ date : Date, hours : Int, Minutes : Int) -> Date {
        
        var dateComponents : DateComponents = DateComponents()
        dateComponents.hour = hours
        dateComponents.minute = Minutes
        
        let calendar = Calendar.current
        let newDate = (calendar as NSCalendar).date(byAdding: dateComponents, to : date, options: NSCalendar.Options(rawValue: 0))
        
        //TODO: Error handling
        return newDate!
    }
    
    static func subtractDaysFromDate(_ date : Date, days : Int) -> Date {
    
        return addDaysToDate(date, days : (days - (days * 2)))
    }
    
    static func currentDateWithHour(_ hour : Int, minute : Int, second : Int) -> Date {
        
        let date = Date()
        let calendar = Calendar.current
        
        var dateComponents : DateComponents = DateComponents()
        dateComponents.year = (calendar as NSCalendar).component(NSCalendar.Unit.year, from: date)
        dateComponents.month = (calendar as NSCalendar).component(NSCalendar.Unit.month, from: date)
        dateComponents.day = (calendar as NSCalendar).component(NSCalendar.Unit.day, from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        
        return getDateFromComponents(dateComponents)
    }
    
    static func dateStringFromComponents(_ dateComponents : DateComponents) -> String {
        
        let date = Date()
        let calendar = Calendar.current
        
        var currentDateComponents : DateComponents = DateComponents()
        
        (currentDateComponents as NSDateComponents).calendar = calendar
        currentDateComponents.year = (calendar as NSCalendar).component(NSCalendar.Unit.year, from: date)
        currentDateComponents.month = (calendar as NSCalendar).component(NSCalendar.Unit.month, from: date)
        currentDateComponents.day = (calendar as NSCalendar).component(NSCalendar.Unit.day, from: date)
        currentDateComponents.hour = dateComponents.hour
        currentDateComponents.minute = dateComponents.minute
        currentDateComponents.second = dateComponents.second
        
        let currentDate : Date? = (currentDateComponents as NSDateComponents).date
        let dateComponentsDate : Date? = (dateComponents as NSDateComponents).date
        
        let dateCompareResult = currentDate!.compare(dateComponentsDate!)
        
        let displayHour = (dateComponents.hour! > 12) ? dateComponents.hour!-12 : dateComponents.hour
        let displayMinute = (dateComponents.minute! < 10) ? "0\(dateComponents.minute)" : String(describing: dateComponents.minute)
        let displayAMPM = (dateComponents.hour! > 12) ? "PM" : "AM"
        
        let timeString : String = "\(displayHour):\(displayMinute) \(displayAMPM)"
        
        var dateString : String
        
        switch dateCompareResult {
            
        case ComparisonResult.orderedSame:
            dateString = "Today, \(timeString)"
            break
        case ComparisonResult.orderedDescending:
            
            if dateComponents.year! == currentDateComponents.year!
                && dateComponents.year! == currentDateComponents.year!
                && dateComponents.day! == currentDateComponents.day!-1 {
                
                dateString = "Yesterday, \(timeString)"
            }
            else {
                
                dateString = "\(dateComponents.day)/\(dateComponents.month)/\(dateComponents.year), \(timeString)"
            }
            break
        case ComparisonResult.orderedAscending:
            dateString = "Tomorrow, \(timeString)"
            break
        }
        
        return dateString
    }
    
    static func dateIsBeforeDate(_ date1 : Date, date2 : Date) -> Bool {
        
        let dateCompareResult = date1.compare(date2)
        
        return dateCompareResult == ComparisonResult.orderedDescending
    }
    
    static func dateIsAfterDate(_ date1 : Date, date2 : Date) -> Bool {
        
        let dateCompareResult = date1.compare(date2)
        
        return dateCompareResult == ComparisonResult.orderedAscending
    }
    
    static func getDateFromComponents(_ components : DateComponents) -> Date {
        
        let gregorian = Calendar(identifier:Calendar.Identifier.gregorian)
        let date = gregorian.date(from: components)
        
        return date!
    }
    
    static func getDateComponentsFromDate(_ date : Date) -> DateComponents {
    
        let calendar = Calendar.current
        var dateComponents : DateComponents = DateComponents()
        
        (dateComponents as NSDateComponents).calendar = calendar
        dateComponents.year = (calendar as NSCalendar).component(NSCalendar.Unit.year, from: date)
        dateComponents.month = (calendar as NSCalendar).component(NSCalendar.Unit.month, from: date)
        dateComponents.day = (calendar as NSCalendar).component(NSCalendar.Unit.day, from: date)
        dateComponents.hour = (calendar as NSCalendar).component(NSCalendar.Unit.hour, from: date)
        dateComponents.minute = (calendar as NSCalendar).component(NSCalendar.Unit.minute, from: date)
        dateComponents.second = (calendar as NSCalendar).component(NSCalendar.Unit.second, from: date)

        return dateComponents;
    }
}
