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
    
    //Setter for the cells reminder
    var reminder: EKReminder? {
        didSet {
            
//            if let shoppingListItemReminder = reminder{
//                
//                //Setting the text value based on the auto-capitalisation settings
//                shoppingListItemTextField.attributedText = nil
//                shoppingListItemTextField.text = getAutoCapitalisationTitle(shoppingListItemReminder.title)
//                
//                //Extra section for completed items
//                setShoppingListItemCompletedText(shoppingListItemReminder)
//            }
        }
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews();
        
        if let shoppingListItemReminder = reminder{
            
            self.layer.backgroundColor = Utility.itemIsInShoppingCart(shoppingListItemReminder)
                ? UIColor(red:0.00, green:0.50196081400000003, blue:1, alpha:1.0).CGColor
                : UIColor.whiteColor().CGColor
        }
    }
    
    func setShoppingListItem(reminder: EKReminder) {
        
        self.reminder = reminder
        
        shoppingListItemTextField.attributedText = nil
        shoppingListItemTextField.text = getAutoCapitalisationTitle(reminder.title)

        //Extra section for completed items
        setShoppingListItemCompletedText(reminder)
        
        shoppingListItemTextField.delegate = self
    }
    
    @IBAction func addNewTouchUpInside(sender: AnyObject) {
        
        //When the '+' is clicked we bring up the keyboard for the text field
        shoppingListItemTextField.becomeFirstResponder()
    }
    
    //When editing has finished on the text field, save the reminder
    @IBAction func shoppingListItemTextFieldEditingDidEnd(sender: UITextField) {
        
        sender.resignFirstResponder()
        
        if let editedReminder = reminder{
            
            if sender.text != "" {
                
                editedReminder.title = sender.text!
                
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SaveReminder, object: editedReminder)
            }
        }
    }
    
    //When an item is marked as complete or in-complete.
    //Add a small delay for useability so the item doesn't go off the list straight away
    @IBAction func completedSwitchValueChanged(sender: AnyObject) {
        
        if let checkSwitch = sender as? UISwitch{
            
            if let editedReminder = reminder{
                
                editedReminder.completed = !checkSwitch.on
                
                if editedReminder.completed {
                    
                    //Add the datetime to the reminder as notes (Jan 27, 2010, 1:00 PM)
                    let dateformatter = NSDateFormatter()
                    
                    dateformatter.dateStyle = NSDateFormatterStyle.MediumStyle
                    dateformatter.timeStyle = NSDateFormatterStyle.ShortStyle

                    editedReminder.notes = dateformatter.stringFromDate(NSDate())
                }
                else {
                    
                    editedReminder.notes = nil
                }
                
                let delayInMilliSeconds = (editedReminder.completed) ? 500.0 : 200.00
                
                //The dalay is in nano seconds so we just convert it using the standard NSEC_PER_MSEC value
                let delay = Int64(delayInMilliSeconds * Double(NSEC_PER_MSEC))
                
                let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, delay)
                dispatch_after(dispatchTime, dispatch_get_main_queue()) {
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SaveReminder, object: editedReminder)
                }
            }
        }
    }
//    
//    func setShoppingListItem(reminder: EKReminder) {
//        
//        self.reminder = reminder
//        
//        shoppingListItemTextField.delegate = self
//    }
    
    //Return the title based on the auto-capitalisation settings
    func getAutoCapitalisationTitle(title : String) -> String {
        
        var listItem = title
            
        //Split the string into an array of strings around the ' ' character
        let words = listItem.componentsSeparatedByString(" ")
        
        listItem = words[0]
        
        //Loop through each word in the string and make it lower case or first letter upper-case
        for var i = 1; i < words.count; ++i {
            
            if SettingsUserDefaults.autoCapitalisation {
                
                listItem = listItem + " " + words[i].capitalizedString
            }
            else{
                
                listItem = listItem + " " + words[i].lowercaseString
            }
        }
        
        return listItem
    }
    
    //Puts a strike through the text of completed items
    func setShoppingListItemCompletedText(shoppingListItemReminder : EKReminder) {
        
        completedSwitch.on = !shoppingListItemReminder.completed
        
        if let checkSwitch = completedSwitch {
            
            switch shoppingListItemReminder.title{
                
                case Constants.ShoppingListItemTableViewCell.EmptyCell:
                    checkSwitch.hidden = true
                    addNewButton.hidden = true
                    shoppingListItemTextField.text = ""
                case Constants.ShoppingListItemTableViewCell.NewItemCell:
                    checkSwitch.hidden = true
                    addNewButton.hidden = false
                    shoppingListItemTextField.text = ""
                default:
                    checkSwitch.hidden = false
                    addNewButton.hidden = true
            }
            
            if !checkSwitch.on && shoppingListItemReminder.notes == nil {
                
                let string = shoppingListItemReminder.title as NSString
                
                let attributedString = NSMutableAttributedString(string: string as String)
                let attributes = [NSStrikethroughStyleAttributeName: 1]
                
                attributedString.addAttributes(attributes, range: string.rangeOfString(string as String))
                
                shoppingListItemTextField.attributedText = attributedString
            }
        }
    }
    
    //delegate method for when the return button is pressed
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}
