//
//  ShoppingListItemTableViewCell.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 25/08/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class ShoppingListItemTableViewCell: UITableViewCell, UITextViewDelegate
{
    @IBOutlet weak var shoppingListItemTextView: UITextView!
    
    @IBOutlet weak var completedSwitch: UISwitch!
    
    @IBOutlet weak var addNewButton: UIButton!
    
    @IBOutlet weak var completedSwitchView: UIView!
    
    weak var reminderSortViewController : ReminderSortViewController!
    
    var inactiveLockObserver : NSObjectProtocol?
    var itemBeginEditingObserver : NSObjectProtocol?
    
    var textViewCanResignFirstResponder: Bool = true
    
    //Setter for the cells reminder
    var reminder: ShoppingListItem?
    
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
        
        if let observer = itemBeginEditingObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil)
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
        
        if reminderSortViewController != nil {
        
            setInactiveLock(reminderSortViewController.inactiveLock)
        }
    }
    
    @objc func viewPressed(_ gestureRecognizer: UIGestureRecognizer) {
        
        if completedSwitch.isEnabled {

            if let editedReminder = reminder { 
                
                if !reminderIsInHistory() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ResetLock), object: self)
                }
                                
                editedReminder.completed = completedSwitch.isOn
                completedSwitch.setOn(!completedSwitch.isOn, animated: true)

                editedReminder.notes = Utility.getDateForNotes()

                let delayInMilliSeconds = (editedReminder.completed) ? 200.0 : 200.00
                
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
        
        itemBeginEditingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil, queue: nil){
            (notification) -> Void in
            
            if let isEditing = notification.object as? Bool {
                
                self.completedSwitch.isEnabled = !isEditing
            }
        }
    }
    
    func reminderIsInHistory() -> Bool {
        
        return reminder!.completed
            && !Utility.itemIsInShoppingCart(reminder!)
    }
    
    func setInactiveLock(_ lock: Bool) {
        
        if reminder != nil {
            
            completedSwitch.isEnabled = !lock || reminderIsInHistory()
            shoppingListItemTextView.isEditable = !lock || reminderIsInHistory()
            shoppingListItemTextView.isSelectable = !lock || reminderIsInHistory()
        }
    }
    
    func setShoppingListItem(_ reminder: ShoppingListItem) {
        
        self.reminder = reminder
        
        let attributes = [ NSAttributedStringKey.font: Constants.ShoppingListItemFont ]
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
    func setShoppingListItemCompletedText(_ shoppingListItemReminder : ShoppingListItem) {
        
        if let checkSwitch = completedSwitch {
            
            checkSwitch.isOn = !shoppingListItemReminder.completed
            
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
            
            if Utility.itemIsInShoppingCart(shoppingListItemReminder) {
                
                let string = shoppingListItemReminder.title as NSString
                
                let attributedString = NSMutableAttributedString(string: string as String)
                
                let attributes = [NSAttributedStringKey.strikethroughStyle: 1, NSAttributedStringKey.font: Constants.ShoppingListItemFont] as [NSAttributedStringKey : Any]
                
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
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        let pointInTable:CGPoint = textView.superview!.convert(textView.frame.origin, to:reminderSortViewController.remindersTableView)
        var contentOffset:CGPoint = reminderSortViewController.remindersTableView.contentOffset
        
        contentOffset.y = pointInTable.y
        
        // We don't actually use this here (inputAccessoryView that is), but keep it here for future reference
        if let accessoryView = textView.inputAccessoryView {
            contentOffset.y -= (accessoryView.frame.size.height)
        }
        
        reminderSortViewController.remindersTableView.contentOffset = contentOffset
        
        if shoppingListItemTextView.isEditable && reminderSortViewController.refreshLock.try() {
            
            reminderSortViewController.tableView.isScrollEnabled = false
            
            return shoppingListItemTextView.isEditable
        }
        
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {

//        let pointInTable:CGPoint = textView.superview!.convert(textView.frame.origin, to:reminderSortViewController.remindersTableView)
//        var contentOffset:CGPoint = reminderSortViewController.remindersTableView.contentOffset
//        contentOffset.y  = pointInTable.y
//        if let accessoryView = textView.inputAccessoryView {
//            contentOffset.y -= (accessoryView.frame.size.height + accessoryView.frame.size.height + accessoryView.frame.size.height)
//        }
//        
//        reminderSortViewController.remindersTableView.contentOffset = contentOffset
        
        reminderSortViewController.setupRightBarButtons(true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ItemEditing), object: true)
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        return !textViewCanResignFirstResponder
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        textViewCanResignFirstResponder = true
        
        reminderSortViewController.tableView.isScrollEnabled = true
        
        if let editedReminder = reminder {

            if textView.text != "" {

                editedReminder.title = textView.text!
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SaveReminder), object: editedReminder)
            }
        }
        
        reminderSortViewController.refreshLock.unlock()

        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ItemEditing), object: false)
    }
    
    func isShoppingListItemEditing() -> Bool {
        
        return shoppingListItemTextView.isFirstResponder
    }
}
