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
    //var originalText = ""
    //var cellIsEdited = false
    
    @IBOutlet weak var shoppingListItemTextField: UITextField!
    
    @IBOutlet weak var completedSwitch: UISwitch!
    
    weak var reminderSortViewController : ReminderSortViewController?
    
    //REVISIT: This could be a huge problem as it may stick around in memory...
    var reminder: EKReminder? {
        didSet {
            
            if let shoppingListItemReminder = reminder{
                
                shoppingListItemTextField.text = shoppingListItemReminder.title
                completedSwitch.on = !shoppingListItemReminder.completed
                
                if let checkSwitch = completedSwitch{
                    
                    checkSwitch.hidden = shoppingListItemReminder.title == ""
                    
                    if !checkSwitch.on{
                        
                        let string = shoppingListItemReminder.title as NSString
                        
                        var attributedString = NSMutableAttributedString(string: string as String)
                        let attributes = [NSStrikethroughStyleAttributeName: 1]
                        attributedString.addAttributes(attributes, range: string.rangeOfString(string as String))
                        
                        shoppingListItemTextField.attributedText = attributedString
                    }
                }
            }
        }
    }
    
    @IBAction func shoppingListItemTextFieldEditingDidEnd(sender: UITextField) {
        
        sender.resignFirstResponder()
        
        if let editedReminder = reminder{
            
            if sender.text != ""{
                
                editedReminder.title = sender.text
                
                if let viewController = reminderSortViewController{
                    
                    reminderSortViewController!.saveReminder(editedReminder)
                }
            }
        }
    }
    
    @IBAction func completedSwitchValueChanged(sender: AnyObject) {
        
        if let checkSwitch = sender as? UISwitch{
            
            if let editedReminder = reminder{
                
                editedReminder.completed = !checkSwitch.on
                
                if let viewController = reminderSortViewController{
                    
                    reminderSortViewController!.saveReminder(editedReminder)
                }
            }
        }
    }
    
    func setShoppingListItem(reminder: EKReminder){
        
        self.reminder = reminder
        
        shoppingListItemTextField.delegate = self
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        
        textField.resignFirstResponder()
        return true
    }
}
