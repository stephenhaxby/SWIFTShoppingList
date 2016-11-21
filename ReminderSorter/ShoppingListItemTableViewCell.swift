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
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.InactiveLock), object: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        
        if let shoppingListItemReminder = reminder {
            
            self.layer.backgroundColor = Utility.itemIsInShoppingCart(shoppingListItemReminder)
                ? UIColor(red:0.00, green:0.50196081400000003, blue:1, alpha:0.5).cgColor
                : UIColor.clear.cgColor
        }
        
        let pressGesture : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.viewPressed(_:)))
        pressGesture.delegate = self
        pressGesture.numberOfTapsRequired = 1
        
        if completedSwitchView != nil {
        
            completedSwitchView.addGestureRecognizer(pressGesture)
        }
        
        setInactiveLock(reminderSortViewController.inactiveLock)
    }
    
    func viewPressed(_ gestureRecognizer: UIGestureRecognizer) {
        
        if completedSwitch.isEnabled {

            if let editedReminder = reminder {
                
                if reminderIsNotInHistory() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ResetLock), object: self)
                }
                                
                editedReminder.isCompleted = completedSwitch.isOn
                completedSwitch.setOn(!completedSwitch.isOn, animated: true)

                if editedReminder.isCompleted {
                    
                    //Add the datetime to the reminder as notes (Jan 27, 2010, 1:00 PM)
                    let dateformatter = DateFormatter()
                    
                    dateformatter.dateStyle = DateFormatter.Style.medium
                    dateformatter.timeStyle = DateFormatter.Style.short

                    editedReminder.notes = dateformatter.string(from: Date())
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SetClearShoppingList), object: self)
                }
                else {
                    
                    editedReminder.notes = nil
                }

                let delayInMilliSeconds = (editedReminder.isCompleted) ? 500.0 : 200.00
                
                //The dalay is in nano seconds so we just convert it using the standard NSEC_PER_MSEC value
                let delay = Int64(delayInMilliSeconds * Double(NSEC_PER_MSEC))
                
                let dispatchTime = DispatchTime.now() + Double(delay) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SaveReminder), object: editedReminder)
                }
            }
        }
        else {

            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ActionOnLocked), object: nil)
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {

        if shoppingListItemTextView.isEditable {
            
            reminderSortViewController.refreshLock.lock()
        }
        
        return shoppingListItemTextView.isEditable
    }

    @IBAction func addNewTouchUpInside(_ sender: AnyObject) {
        
        //When the '+' is clicked we bring up the keyboard for the text field
        shoppingListItemTextView.becomeFirstResponder()
    }
    
    func initializeCell() {
        
        //Observer for when our settings change
        inactiveLockObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.InactiveLock), object: nil, queue: nil) {
            (notification) -> Void in
            
            if let lock = notification.object as? Bool {
                
                self.setInactiveLock(lock)
            }
        }
    }
    
    func reminderIsNotInHistory() -> Bool {
        
        return !reminder!.isCompleted
            || Utility.itemIsInShoppingCart(reminder!)
    }
    
    func setInactiveLock(_ lock: Bool) {
        
        if reminder != nil &&
            reminderIsNotInHistory (){
            
            completedSwitch.isEnabled = !lock
            shoppingListItemTextView.isEditable = !lock
            shoppingListItemTextView.isSelectable = !lock
        }
    }
    
    func setShoppingListItem(_ reminder: EKReminder) {
        
        self.reminder = reminder
        
        let attributes = [ NSFontAttributeName: Constants.ShoppingListItemFont ]
        shoppingListItemTextView.attributedText = NSMutableAttributedString(string: getAutoCapitalisationTitle(reminder.title), attributes: attributes)
        
        //Extra section for completed items
        setShoppingListItemCompletedText(reminder)
        
        shoppingListItemTextView.delegate = self
    }
    
    //Return the title based on the auto-capitalisation settings
    func getAutoCapitalisationTitle(_ title : String) -> String {
        
        var listItem = title
            
        //Split the string into an array of strings around the ' ' character
        let words = listItem.components(separatedBy: " ")
        
        listItem = words[0]
        
        //Loop through each word in the string and make it lower case or first letter upper-case
        for i in 1 ..< words.count {
            
            if SettingsUserDefaults.autoCapitalisation {
                
                listItem = listItem + " " + words[i].capitalized
            }
            else{
                
                listItem = listItem + " " + words[i].lowercased()
            }
        }
        
        return listItem
    }
    
    //Puts a strike through the text of completed items
    func setShoppingListItemCompletedText(_ shoppingListItemReminder : EKReminder) {
        
        if let checkSwitch = completedSwitch {
            
            checkSwitch.isOn = !shoppingListItemReminder.isCompleted
            
            switch shoppingListItemReminder.title{
                
                case Constants.ShoppingListItemTableViewCell.EmptyCell:
                    checkSwitch.isHidden = true
                    addNewButton.isHidden = true
                    shoppingListItemTextView.text = ""
                case Constants.ShoppingListItemTableViewCell.NewItemCell:
                    checkSwitch.isHidden = true
                    addNewButton.isHidden = false
                    shoppingListItemTextView.text = ""
                default:
                    checkSwitch.isHidden = false
                    addNewButton.isHidden = true
            }
            
            if !checkSwitch.isOn && shoppingListItemReminder.notes == nil {
                
                let string = shoppingListItemReminder.title as NSString
                
                let attributedString = NSMutableAttributedString(string: string as String)
                
                let attributes = [NSStrikethroughStyleAttributeName: 1, NSFontAttributeName: Constants.ShoppingListItemFont] as [String : Any]
                
                attributedString.addAttributes(attributes, range: string.range(of: string as String))
                
                shoppingListItemTextView.attributedText = attributedString
            }
        }
    }
    
    //Delegate method for text changing on the cells UITextView
    func textViewDidChange(_ textView: UITextView) {
        
        if let tableView = reminderSortViewController.tableView {
            
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
        
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        reminderSortViewController.setupRightBarButtons(true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ItemEditing), object: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if let editedReminder = reminder {

            if textView.text != "" {

                editedReminder.title = textView.text!

                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SaveReminder), object: editedReminder)
            }
        }
        
        reminderSortViewController.refreshLock.unlock()

        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ItemEditing), object: false)
    }
}
