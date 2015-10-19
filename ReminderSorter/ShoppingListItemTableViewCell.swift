//
//  ShoppingListItemTableViewCell.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 25/08/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit
import EventKit

class ShoppingListItemTableViewCell: UITableViewCell, UITextFieldDelegate
{   
    @IBOutlet weak var shoppingListItemTextField: UITextField!
    
    @IBOutlet weak var completedSwitch: UISwitch!
    
    @IBOutlet weak var addNewButton: UIButton!
    
    weak var reminderSortViewController : ReminderSortViewController?
    
    //REVISIT: This could be a huge problem as it may stick around in memory...
    var reminder: EKReminder? {
        didSet {
            
            if let shoppingListItemReminder = reminder{
                
                shoppingListItemTextField.text = getAutoCapitalisationTitle(shoppingListItemReminder.title)
                
                setShoppingListItemCompletedText(shoppingListItemReminder)
            }
        }
    }
    
    @IBAction func shoppingListItemTextFieldEditingDidEnd(sender: UITextField) {
        
        sender.resignFirstResponder()
        
        if let editedReminder = reminder{
            
            if sender.text != "" {
                
                editedReminder.title = sender.text!
                
                if let viewController = reminderSortViewController{
                    
                    viewController.saveReminder(editedReminder)
                }
            }
        }
    }
    
    @IBAction func completedSwitchValueChanged(sender: AnyObject) {
        
        if let checkSwitch = sender as? UISwitch{
            
            if let editedReminder = reminder{
                
                editedReminder.completed = !checkSwitch.on
                
                if let viewController = reminderSortViewController{
                    
                    let delayInMilliSeconds = (editedReminder.completed) ? 500.0 : 200.00
                    
                    //The dalay is in nano seconds so we just convert it using the standard NSEC_PER_MSEC value
                    let delay = Int64(delayInMilliSeconds * Double(NSEC_PER_MSEC))
                    
                    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, delay)
                    dispatch_after(dispatchTime, dispatch_get_main_queue()) {
                        
                        viewController.saveReminder(editedReminder)
                    }
                }
            }
        }
    }
    
    func setShoppingListItem(reminder: EKReminder) {
        
        self.reminder = reminder
        
        shoppingListItemTextField.delegate = self
    }
    
    func getAutoCapitalisationTitle(title : String) -> String {
        
        var listItem = title
        
        if let viewController = reminderSortViewController {
            
            let words = listItem.componentsSeparatedByString(" ")
            
            listItem = words[0]
            
            for var i = 1; i < words.count; ++i{
                
                if viewController.autocapitalisation {
                    
                    listItem = listItem + " " + words[i].capitalizedString
                }
                else{
                    
                    listItem = listItem + " " + words[i].lowercaseString
                }
            }
        }
        
        return listItem
    }
    
    func setShoppingListItemCompletedText(shoppingListItemReminder : EKReminder) {
        
        completedSwitch.on = !shoppingListItemReminder.completed
        
        if let checkSwitch = completedSwitch {
            
            checkSwitch.hidden = shoppingListItemReminder.title == ""
            addNewButton.hidden = !checkSwitch.hidden
            
            if !checkSwitch.on{
                
                let string = shoppingListItemReminder.title as NSString
                
                let attributedString = NSMutableAttributedString(string: string as String)
                let attributes = [NSStrikethroughStyleAttributeName: 1]
                
                attributedString.addAttributes(attributes, range: string.rangeOfString(string as String))
                
                shoppingListItemTextField.attributedText = attributedString
            }
        }
    }
    
    //delegate method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}
