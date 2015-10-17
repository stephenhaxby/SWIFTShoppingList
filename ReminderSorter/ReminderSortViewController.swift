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
    
    var alphabeticalSortIncomplete : Bool = true
    var alphabeticalSortComplete : Bool = true
    var autocapitalisation : Bool = true
    
    var eventStoreObserver : NSObjectProtocol?
    var settingsObserver : NSObjectProtocol?
    
    let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setSettings()
        
        //Observer for the app for when the event store is changed in the background (or when our app isn't running)
        eventStoreObserver = NSNotificationCenter.defaultCenter().addObserverForName(EKEventStoreChangedNotification, object: nil, queue: nil){
            (notification) -> Void in
            self.refresh()
        }
        
        //Observer for when our settings change
        settingsObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil){
            (notification) -> Void in
            
            self.setSettings()
            self.refresh()
        }
        
        eventStoreObserver = NSNotificationCenter.defaultCenter().addObserverForName("QuickScrollButtonPressed", object: nil, queue: nil){
            (notification) -> Void in
            
            if let quickScrollButton : UIButton = notification.object as? UIButton {

                self.scrollToLetter(quickScrollButton.currentTitle!)
            }
        }
    }
    
    deinit{
        
        if let observer = eventStoreObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: EKEventStoreChangedNotification, object: nil)
        }
        
        if let observer = settingsObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: NSUserDefaultsDidChangeNotification, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0)]
        
        startRefreshControl()
        
        reminderManager.remindersListName = "Shopping"
        reminderManager.requestAccessToReminders(requestedAccessToReminders)
    }
    
    override func shouldAutorotate() -> Bool {
        
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask{
        
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        
        return UIInterfaceOrientation.Portrait
    }
    
    //Event for pull down to refresh
    @IBAction private func refresh(sender: UIRefreshControl?) {
        
        //reminderManager.eventStore.refreshSourcesIfNecessary()
        
        loadShoppingList()
        
        endRefreshControl(sender)
    }
    
    func setSettings(){
        
        alphabeticalSortIncomplete = NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortIncomplete")
        alphabeticalSortComplete = NSUserDefaults.standardUserDefaults().boolForKey("alphabeticalSortComplete")
        autocapitalisation = NSUserDefaults.standardUserDefaults().boolForKey("autocapitalisation")
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
        else{
            
            displayError("Please allow Shopping to access 'Reminders'...")
        }
        
        endRefreshControl()
    }
    
    //Once the reminders have been loaded from iCloud
    func getShoppingList(iCloudShoppingList : [EKReminder]){
        
        func reminderSort(reminder1: EKReminder, reminder2: EKReminder) -> Bool {
            
            return reminder1.title.lowercaseString < reminder2.title.lowercaseString
        }
        
        var itemsToGet : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in !reminder.completed})
        var completedItems : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in reminder.completed})
            
        if alphabeticalSortIncomplete {
            
            itemsToGet = itemsToGet.sort(reminderSort)
        }
        
        if alphabeticalSortComplete {

            completedItems = completedItems.sort(reminderSort)
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            if let shoppingListTable = self.tableView{

                self.shoppingList = itemsToGet + completedItems
                
                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
        }
    }

    func saveReminder(reminder : EKReminder){
        
        guard reminderManager.saveReminder(reminder) else {
            
            displayError("Your shopping list item could not be saved...")
            
            return
        }
        
        refresh()
    }

    func displayError(message : String){
        
        //Display an alert to specify that we couldn't get access
        let errorAlert = UIAlertController(title: "Error!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        //Add an Ok button to the alert
        errorAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:
            { (action: UIAlertAction!) in
                
        }))
        
        //Present the alert
        self.presentViewController(errorAlert, animated: true, completion: nil)
    }
    
    func scrollToLetter(letter: String){
        
        if letter == "+"{
            
            let indexPath = NSIndexPath(forRow: shoppingList.count, inSection: 0)

            remindersTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        else{
            
            scrollToNearestLetter(letter)
        }
    }
    
    func scrollToNearestLetter(letter: String){
        
        var itemsBeginingWith : [EKReminder] = shoppingList.filter({(reminder : EKReminder) in reminder.completed && reminder.title.hasPrefix(letter)})
        
        if itemsBeginingWith.count > 0{
            
            let index = shoppingList.indexOf(itemsBeginingWith[0])
            
            let indexPath = NSIndexPath(forRow: index!, inSection: 0)
            
            remindersTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        else{
            
            //If no items exist that start with that letter, go back up the alphabet to find one that exists
            
            let indexOfLetter = alphabet.indexOf(letter)
            
            if(indexOfLetter > 0){
                
                scrollToNearestLetter(alphabet[indexOfLetter!-1])
            }
            else{
                
                remindersTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            }
        }
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
        
        if autocapitalisation{
            
            cell.shoppingListItemTextField.autocapitalizationType = UITextAutocapitalizationType.Words
        }
        else{
            
            cell.shoppingListItemTextField.autocapitalizationType = UITextAutocapitalizationType.Sentences
        }
        
        
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
            
            //TODO: We ended up in a situation where indexPath.row = 10 but shoppingList had 0 elements in it...
            
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
            
            guard reminderManager.removeReminder(shoppingListItem) else {
                
                displayError("Your shopping list item could not be removed...")
                
                return
            }
        }
        
        refresh()
    }
}

















