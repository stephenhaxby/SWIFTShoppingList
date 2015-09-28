//
//  ReminderSortViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 15/06/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit
import EventKit

class ReminderSortViewController: UITableViewController {
    
    //Outlet for the Table View so we can access it in code
    @IBOutlet var remindersTableView: UITableView!
    
    let reminderManager : iCloudReminderManager = iCloudReminderManager()
    
    var shoppingList = [EKReminder]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0)]
        
        startRefreshControl()
        
        reminderManager.remindersListName = "Shopping"
        reminderManager.requestAccessToReminders(requestedAccessToReminders)
    }
    
    //Event for pull down to refresh
    @IBAction private func refresh(sender: UIRefreshControl?) {
        
        loadShoppingList()
        
        endRefreshControl(sender)
    }
    
    //Gets the shopping list from the manager and reloads the table
    func loadShoppingList(){
        
        reminderManager.getReminders(getShoppingList)
    }
    
    //Called by the table view cell when deleting an item
    func refresh(){
        
        startRefreshControl()
        
        loadShoppingList()
        
        endRefreshControl()
    }
    
    func startRefreshControl(){
        
        if let refresh = refreshControl{
            
            refresh.beginRefreshing()
        }
    }
    
    func endRefreshControl(){
        
        if let refresh = refreshControl{
            
            refresh.endRefreshing()
        }
    }
    
    func endRefreshControl(sender: UIRefreshControl?){
        
        if let refresh = sender{
            
            refresh.endRefreshing()
        }
    }
    
    //Once access is granted to the reminders list
    func requestedAccessToReminders(status : Bool){
        
        if status {
            
            loadShoppingList()
        }
        
        //TODO: Report if it failed...
        endRefreshControl()
    }
    
    //Once the reminders have been loaded from iCloud
    func getShoppingList(iCloudShoppingList : [EKReminder]){
        
        shoppingList = [EKReminder]()
        
        func reminderSort(reminder1: EKReminder, reminder2: EKReminder) -> Bool {
            
            return reminder1.title.lowercaseString < reminder2.title.lowercaseString
        }
        
        let itemsToGet : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in !reminder.completed}).sort(reminderSort)
        let completedItems : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in reminder.completed}).sort(reminderSort)
        
        shoppingList = itemsToGet + completedItems
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            if let shoppingListTable = self.tableView{
                
                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
        }
    }

    func saveReminder(reminder : EKReminder){
        
        reminderManager.saveReminder(reminder)
        
        refresh()
    }

    // MARK: - UITableViewDataSource
    
    //To return the number of items that the table view needs to show
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return shoppingList.count + 1
    }
    
    //To populate each cell's text based on the index into the calendars array
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var shoppingListItem : EKReminder?
        
        let cell : ShoppingListItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("ReminderCell") as! ShoppingListItemTableViewCell
        cell.shoppingListItemTextField.autocapitalizationType = UITextAutocapitalizationType.Words
        
        if indexPath.row == shoppingList.count{
            
            shoppingListItem = reminderManager.getNewReminder()
            
            //getNewReminder can return nil if the EventStore isn't ready. This happens when the table is first loaded...
            if shoppingListItem == nil{
                
                return ShoppingListItemTableViewCell()
            }
            
            shoppingListItem!.title = ""
            shoppingListItem!.completed = false
        }
        else{
            
            shoppingListItem = shoppingList[indexPath.row]
        }
        
        cell.reminderSortViewController = self
        cell.setShoppingListItem(shoppingListItem!)
        
        return cell
    }
    
    //CUSTOM EDIT ROW ACTIONS
//    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
//        
//        let more = UITableViewRowAction(style: .Normal, title: "More") { action, index in
//            println("more button tapped")
//        }
//        more.backgroundColor = UIColor.lightGrayColor()
//        
//        let favorite = UITableViewRowAction(style: .Normal, title: "Favorite") { action, index in
//            println("favorite button tapped")
//        }
//        favorite.backgroundColor = UIColor.orangeColor()
//        
//        let share = UITableViewRowAction(style: .Normal, title: "Share") { action, index in
//            println("share button tapped")
//        }
//        share.backgroundColor = UIColor.blueColor()
//        
//        return [share, favorite, more]
//    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        
        //Don't allow delete of the last blank row...
        if(indexPath.row < shoppingList.count){
            return true
        }
        
        return false
    }

    //This method is for the swipe left to delete
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // you need to implement this method too or you can't swipe to display the actions
        
        if(indexPath.row < shoppingList.count){

            let shoppingListItem : EKReminder = shoppingList[indexPath.row]
            
            reminderManager.removeReminder(shoppingListItem)
        }
        
        refresh()
    }
}

















