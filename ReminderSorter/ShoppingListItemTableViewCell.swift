//
//  ShoppingListItemTableViewCell.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 25/08/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit
import EventKit

class ShoppingListItemTableViewCell: UITableViewCell, UITextViewDelegate
{
    @IBOutlet weak var shoppingListItemTextView: UITextView!
    
    @IBOutlet weak var completedSwitch: UISwitch!
    
    @IBOutlet weak var addNewButton: UIButton!
    
    @IBOutlet weak var completedSwitchView: UIView!
    
    weak var reminderSortViewController : ReminderSortViewController!
    
    var inactiveLockObserver : NSObjectProtocol?
    
    //Setter for the cells reminder
    var reminder: EKReminder?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initializeCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initializeCell()
    }

    deinit {
        
        if let observer = inactiveLockObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.InactiveLock, object: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        
        if let shoppingListItemReminder = reminder {
            
            self.layer.backgroundColor = Utility.itemIsInShoppingCart(shoppingListItemReminder)
                ? UIColor(red:0.00, green:0.50196081400000003, blue:1, alpha:0.5).CGColor
                : UIColor.clearColor().CGColor
        }
        
        let pressGesture : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.viewPressed(_:)))
        pressGesture.delegate = self
        pressGesture.numberOfTapsRequired = 1
        
        completedSwitchView.addGestureRecognizer(pressGesture)
    }
    
    func viewPressed(gestureRecognizer: UIGestureRecognizer) {
        
        if completedSwitch.enabled {

            if let editedReminder = reminder {
                
                editedReminder.completed = completedSwitch.on
                completedSwitch.setOn(!completedSwitch.on, animated: true)

                if editedReminder.completed {
                    
                    //Add the datetime to the reminder as notes (Jan 27, 2010, 1:00 PM)
                    let dateformatter = NSDateFormatter()
                    
                    dateformatter.dateStyle = NSDateFormatterStyle.MediumStyle
                    dateformatter.timeStyle = NSDateFormatterStyle.ShortStyle

                    editedReminder.notes = dateformatter.stringFromDate(NSDate())
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SetClearShoppingList, object: self)
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
        else {

            NSNotificationCenter.defaultCenter().postNotificationName(Constants.ActionOnLocked, object: nil)
        }
    }

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {

        if !shoppingListItemTextView.editable {
            
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.ActionOnLocked, object: nil)
        }
        else {
            
            reminderSortViewController.refreshLock.lock()
        }
        
        return shoppingListItemTextView.editable
    }

    @IBAction func addNewTouchUpInside(sender: AnyObject) {
        
        //When the '+' is clicked we bring up the keyboard for the text field
        shoppingListItemTextView.becomeFirstResponder()
    }
    
    func initializeCell() {
        
        //Observer for when our settings change
        inactiveLockObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.InactiveLock, object: nil, queue: nil) {
            (notification) -> Void in
            
            if let lock = notification.object as? Bool {
                
                self.setInactiveLock(lock)
            }
        }
    }
    
    func setInactiveLock(lock: Bool) {
        
        completedSwitch.enabled = !lock
        shoppingListItemTextView.editable = !lock
        shoppingListItemTextView.selectable = !lock
    }
    
    func setShoppingListItem(reminder: EKReminder) {
        
        self.reminder = reminder
        
        let attributes = [ NSFontAttributeName: Constants.ShoppingListItemFont ]
        shoppingListItemTextView.attributedText = NSMutableAttributedString(string: getAutoCapitalisationTitle(reminder.title), attributes: attributes)
        
        //Extra section for completed items
        setShoppingListItemCompletedText(reminder)
        
        shoppingListItemTextView.delegate = self
    }
    
    //Return the title based on the auto-capitalisation settings
    func getAutoCapitalisationTitle(title : String) -> String {
        
        var listItem = title
            
        //Split the string into an array of strings around the ' ' character
        let words = listItem.componentsSeparatedByString(" ")
        
        listItem = words[0]
        
        //Loop through each word in the string and make it lower case or first letter upper-case
        for i in 1 ..< words.count {
            
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
        
        if let checkSwitch = completedSwitch {
            
            checkSwitch.on = !shoppingListItemReminder.completed
            
            switch shoppingListItemReminder.title{
                
                case Constants.ShoppingListItemTableViewCell.EmptyCell:
                    checkSwitch.hidden = true
                    addNewButton.hidden = true
                    shoppingListItemTextView.text = ""
                case Constants.ShoppingListItemTableViewCell.NewItemCell:
                    checkSwitch.hidden = true
                    addNewButton.hidden = false
                    shoppingListItemTextView.text = ""
                default:
                    checkSwitch.hidden = false
                    addNewButton.hidden = true
            }
            
            if !checkSwitch.on && shoppingListItemReminder.notes == nil {
                
                let string = shoppingListItemReminder.title as NSString
                
                let attributedString = NSMutableAttributedString(string: string as String)
                
                let attributes = [NSStrikethroughStyleAttributeName: 1, NSFontAttributeName: Constants.ShoppingListItemFont]
                
                attributedString.addAttributes(attributes, range: string.rangeOfString(string as String))
                
                shoppingListItemTextView.attributedText = attributedString
            }
        }
    }
    
    //Delegate method for text changing on the cells UITextView
    func textViewDidChange(textView: UITextView) {
        
        if let tableView = reminderSortViewController.tableView {
            
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
        
    func textViewDidBeginEditing(textView: UITextView) {
        
        reminderSortViewController.setupRightBarButtons(true)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if let editedReminder = reminder {

            if textView.text != "" {

                editedReminder.title = textView.text!

                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SaveReminder, object: editedReminder)
            }
        }
        
        reminderSortViewController.refreshLock.unlock()
    }
}
