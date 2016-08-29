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
    
    var refreshLock : NSLock = NSLock()
    
    let reminderManager : iCloudReminderManager = iCloudReminderManager()
    
    var shoppingList = [EKReminder]()
    
    var storedShoppingList = [ShoppingListItem]()
    
    var groupedShoppingList = [[EKReminder]]()
    
    var searchText : String = String()

    var eventStoreObserver : NSObjectProtocol?
    var settingsObserver : NSObjectProtocol?
    var quickScrollObserver : NSObjectProtocol?
    var saveReminderObserver : NSObjectProtocol?
    var clearShoppingCartObserver : NSObjectProtocol?
    var clearShopingCartOnOpenObserver : NSObjectProtocol?
    var setClearShoppingCartObserver : NSObjectProtocol?
    var clearShoppingListOnOpenObserver : NSObjectProtocol?
    var searchBarTextDidChangeObserver : NSObjectProtocol?
    var searchBarCancelObserver : NSObjectProtocol?
    var setRefreshLock : NSObjectProtocol?
    
    var defaults : NSUserDefaults {
        
        get {
            
            return NSUserDefaults.standardUserDefaults()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //TODO: Use a loop and the constant value
        
        for _ in 0..<Constants.ShoppingListSections {
            
            groupedShoppingList.append([EKReminder]())
        }
        
        //Used for when the app goes into the background (as we want to commit any changes...)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.reminderSortViewController = self
        
        //Observer for the app for when the event store is changed in the background (or when our app isn't running)
        eventStoreObserver = NSNotificationCenter.defaultCenter().addObserverForName(EKEventStoreChangedNotification, object: nil, queue: nil){
            (notification) -> Void in
            
            //<NSRecursiveLock: 0x79e264d0>{locked = YES, thread = 0x2dcf000, recursion count = 2, name = nil}
            
            if self.refreshLock.tryLock() {
            
                //Reload the grid only if there are new items from iCloud that we don't have
                self.conditionalLoadShoppingList()
                
                self.refreshLock.unlock()
            }
        }
        
        //Observer for when our settings change
        settingsObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil){
            (notification) -> Void in
            
            self.refresh()
        }
        
        //Custom observer for when a quickscroll button is pressed
        quickScrollObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.QuickScrollButtonPressed, object: nil, queue: nil){
            (notification) -> Void in
            
            if let quickScrollButton : UIButton = notification.object as? UIButton {

                self.scrollToLetter(quickScrollButton.currentTitle!)
            }
        }
        
        //Custom observer for when an cell / reminder needs to be saved
        saveReminderObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SaveReminder, object: nil, queue: nil){
            (notification) -> Void in
            
            if let reminder : EKReminder = notification.object as? EKReminder{

                self.saveReminder(reminder)
            }
        }
        
        clearShoppingCartObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.ClearShoppingList, object: nil, queue: nil){
            (notification) -> Void in
            
            self.clearShoppingCart()
        }
        
        setClearShoppingCartObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SetClearShoppingList, object: nil, queue: nil){
            (notification) -> Void in
            
            self.setClearShoppingCart()
        }
        
        clearShoppingListOnOpenObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.ClearShoppingListOnOpen, object: nil, queue: nil){
            (notification) -> Void in
            
            self.CearShoppingCartOnOpen()
        }
        
        searchBarTextDidChangeObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SearchBarTextDidChange, object: nil, queue: nil){
            (notification) -> Void in
            
            if let searchText = notification.object as? String {
                
                self.searchText = searchText

                self.getShoppingList(self.shoppingList)
            }
        }
        
        searchBarCancelObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SearchBarCancel, object: nil, queue: nil){
            (notification) -> Void in
            
            self.startRefreshControl()
            
            self.searchText = String()
            self.getShoppingList(self.shoppingList)
            
            self.endRefreshControl()
        }
        
        setRefreshLock = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SetRefreshLock, object: nil, queue: nil){
            (notification) -> Void in
            
            if let lock = notification.object as? Bool {
                
                if lock {
                    
                    self.refreshLock.lock()
                }
                else {
                
                    self.refreshLock.unlock()
                }
            }
        }

    }
    
    deinit{
        
        //When this class is dealocated we are removing the observers...
        //Don't really need to do this, but it's nice...
        if let observer = eventStoreObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: EKEventStoreChangedNotification, object: nil)
        }
        
        if let observer = settingsObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: NSUserDefaultsDidChangeNotification, object: nil)
        }
        
        if let observer = quickScrollObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.QuickScrollButtonPressed, object: nil)
        }
        
        if let observer = saveReminderObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.SaveReminder, object: nil)
        }
        
        if let observer = clearShoppingCartObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.ClearShoppingList, object: nil)
        }
        
        if let observer = setClearShoppingCartObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.ClearShoppingList, object: nil)
        }
        
        if let observer = clearShoppingListOnOpenObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.ClearShoppingList, object: nil)
        }
        
        if let observer = searchBarTextDidChangeObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.SearchBarTextDidChange, object: nil)
        }
        
        if let observer = searchBarCancelObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.SearchBarCancel, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Make it so the screen doesn't turn off
        UIApplication.sharedApplication().idleTimerDisabled = SettingsUserDefaults.disableScreenLock
        
        //Set the font size of the navigation view controller
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0)]
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        
        //tableView.registerClass(ShoppingListItemTableViewCell.self, forCellReuseIdentifier: "ReminderCell")
        
        //Set the refresh controll spinning
        startRefreshControl()
        
        //Setup the reminders manager to access a list called 'Shopping'
        reminderManager.remindersListName = Constants.RemindersListName
        
        //Request access to the users reminders list; call 'requestedAccessToReminders' when done
        reminderManager.requestAccessToReminders(requestedAccessToReminders)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
     
        tableView.backgroundColor = .clearColor()
    }
    
    //Event for pull down to refresh
    @IBAction private func refresh(sender: UIRefreshControl?) {
        
        //Delay for 300 milliseconds then run the refresh / commit
        delay(0.3){
        
            self.commitShoppingList()
        }
    }
    
    func clearShoppingCart() {
        
        for shoppingListItem in shoppingList {
            
            if shoppingListItem.notes != nil {
                
                shoppingListItem.notes = nil
                
                saveReminder(shoppingListItem)
            }
        }
        
        if let clearShoppingListNotification : UILocalNotification = getClearShoppingCartNotification() {
            
            UIApplication.sharedApplication().cancelLocalNotification(clearShoppingListNotification) // there should be a maximum of one match on UUID
        }
        
        getShoppingList(shoppingList)
    }
    
    func getClearShoppingCartNotification() -> UILocalNotification? {
        
        var clearShoppingListNotification : UILocalNotification?
        
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! as [UILocalNotification] { // loop through notifications...
            
            if (notification.userInfo!["UUID"] as! String == Constants.SetClearShoppingList) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                
                clearShoppingListNotification = notification
                
                break
            }
        }
        
        return clearShoppingListNotification
    }
    
    func setClearShoppingCart() {
        
        var clearShoppingListNotification : UILocalNotification? = getClearShoppingCartNotification()
        
        if let shoppingCartExpiryTime : NSDate = defaults.objectForKey(Constants.ClearShoppingListExpire) as? NSDate {
            
            let dateComponents : NSDateComponents = NSDateManager.getDateComponentsFromDate(shoppingCartExpiryTime)
            
            if clearShoppingListNotification == nil {
                
                // create a corresponding local notification
                clearShoppingListNotification = UILocalNotification()
                //notification.alertBody = "TEST Alert!" // text that will be displayed in the notification
                //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                
                //notification.soundName = UILocalNotificationDefaultSoundName // play default sound
                clearShoppingListNotification!.userInfo = ["UUID": Constants.SetClearShoppingList] // assign a unique identifier to the notification so that we can retrieve it later
                //notification.category = "TODO_CATEGORY"
                UIApplication.sharedApplication().scheduleLocalNotification(clearShoppingListNotification!)
            }
            
            clearShoppingListNotification!.fireDate = NSDateManager.addHoursAndMinutesToDate(NSDate(), hours: dateComponents.hour, Minutes: dateComponents.minute) // todo item due date (when notification will be fired)

        }
    }
    
    func CearShoppingCartOnOpen() {
        
        //If the notification fires while we are not active it's not in the list anymore so we need to clear it...
        
        if let notification : UILocalNotification = getClearShoppingCartNotification() {
            
            if notification.fireDate != nil && NSDateManager.dateIsAfterDate(notification.fireDate!, date2: NSDate()) {
                
                clearShoppingCart()
            }
        }
        else {
            
            clearShoppingCart()
        }
    }
    
    func commitShoppingList() {
        
        //Add a blank reminder to help trigger an iCloud sync
        if let blankReminder : EKReminder = self.reminderManager.addReminder("", commit: false) {
            
            //Commit all updated items yet to be committed
            self.reminderManager.commit()
            
            //Remove the blank reminder added above
            if !self.reminderManager.removeReminder(blankReminder, commit: true) {
                
                self.displayError("There was a problem refreshing your Shopping List...")
            }
        }
        else {
            
            self.displayError("There was a problem refreshing your Shopping List...")
        }
    }
    
    //Gets the shopping list from the manager and reloads the table
    func loadShoppingList(){
        
        reminderManager.getReminders(getShoppingList)
    }
    
    //Gets the shopping list from the manager and reloads the table ONLY if there are differing items
    func conditionalLoadShoppingList() {
    
        reminderManager.getReminders(conditionalLoadShoppingList)
        endRefreshControl()
    }
    
    //Called by the table view cell when deleting an item
    func refresh(){

        if let shoppingListTable = self.tableView{
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
            
            //shoppingListTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        }
    }
    
    //Delay function to delay the execution of something for a number of seconds
    func delay(delay: Double, closure: ()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(),
            closure
        )
    }
    
    //Only update the shopping list if items have been updated
    func conditionalLoadShoppingList(iCloudShoppingList : [EKReminder]) {

        //Filter out any blank items
        let updatedShoppingList : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in reminder.title != ""})
        
        //Count is different - update the list
        if storedShoppingList.count != updatedShoppingList.count {

            getShoppingList(updatedShoppingList)
        }
        else {

            //Loop for all items in our local list
            for i in 0 ..< storedShoppingList.count {

                //Get the local item
                let currentItem : ShoppingListItem = storedShoppingList[i]
                
                //Find a matching item by ID in the iCloud list
                let updatedItemIndex : Int? = updatedShoppingList.indexOf({(reminder : EKReminder) in reminder.calendarItemExternalIdentifier == currentItem.calendarItemExternalIdentifier})
                
                //If the item exists, check if we need to update our local copy
                if updatedItemIndex != nil {

                    let updatedItem : EKReminder = updatedShoppingList[updatedItemIndex!]

                    if currentItem.completed != updatedItem.completed
                        || currentItem.title != updatedItem.title
                        || currentItem.notes != updatedItem.notes {
                            
                        getShoppingList(updatedShoppingList)
                    }
                }
                else {
                
                    //Item doesn't exist so update our local copy
                    getShoppingList(updatedShoppingList)
                    break
                }
            }
        }
    }
    
    func startRefreshControl(){
        
        if let refresh = refreshControl{
            
            if !refresh.refreshing {
             
                refresh.beginRefreshing()
            }
        }
    }
    
    func endRefreshControl(){
        
        if let refresh = refreshControl{
            
            if refresh.refreshing {
            
                refresh.endRefreshing()
            }
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
        
        createGroupedShoppingList(iCloudShoppingList)
        
        storedShoppingList = [ShoppingListItem]()
        
        //Create backup for conditional loading
        for shoppingListItem in self.shoppingList {
                    
            let storedShoppingListItem : ShoppingListItem = ShoppingListItem()
            storedShoppingListItem.calendarItemExternalIdentifier = shoppingListItem.calendarItemExternalIdentifier
            storedShoppingListItem.title = shoppingListItem.title
            storedShoppingListItem.completed = shoppingListItem.completed
            storedShoppingListItem.notes = shoppingListItem.notes
            
            self.storedShoppingList.append(storedShoppingListItem)
        }

        filterGroupedShoppingList()

        //As we a in another thread, post back to the main thread so we can update the UI
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            if let shoppingListTable = self.tableView {

                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
        }
    }

    func createGroupedShoppingList(iCloudShoppingList : [EKReminder]) {
        
        //var shoppingList = [EKReminder]() // All reminders from the store
        
        //var storedShoppingList = [ShoppingListItem]() // BACKUP
        
        //var groupedShoppingList = [[EKReminder]]() // Datasource
        
        //Small function for sorting reminders
        func reminderSort(reminder1: EKReminder, reminder2: EKReminder) -> Bool {
            
            return reminder1.title.lowercaseString < reminder2.title.lowercaseString
        }
        
        //Find all items that are NOT completed
        var itemsToGet : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in !reminder.completed})
        
        //Find all items that are in the shopping cart
        var itemsGot : [EKReminder] = iCloudShoppingList.filter( {
            (reminder : EKReminder) in
            
            return Utility.itemIsInShoppingCart(reminder)
        })
        
        //Find all items that ARE completed
        var completedItems : [EKReminder] = iCloudShoppingList.filter( {
            (reminder : EKReminder) in
            
            return reminder.completed && !Utility.itemIsInShoppingCart(reminder)
        })
        
        //If the setting specify alphabetical sorting of incomplete items
        if SettingsUserDefaults.alphabeticalSortIncomplete {
            
            itemsToGet = itemsToGet.sort(reminderSort)
        }
        
        if SettingsUserDefaults.alphabeticalSortIncomplete {
            
            itemsGot = itemsGot.sort(reminderSort)
        }
        
        //If the settings specify alphabetical sorting of complete items
        if SettingsUserDefaults.alphabeticalSortComplete {
            
            completedItems = completedItems.sort(reminderSort)
        }
        
        groupedShoppingList[Constants.ShoppingListSection.List.rawValue] = itemsToGet
        groupedShoppingList[Constants.ShoppingListSection.Cart.rawValue] = itemsGot
        groupedShoppingList[Constants.ShoppingListSection.History.rawValue] = completedItems
        
        //Join the two lists from above
        shoppingList = itemsToGet + itemsGot + completedItems
    }
    
    func filterGroupedShoppingList() {

        func reminderTitleContains(reminder : EKReminder, searchText : String) -> Bool {
   
            if SettingsUserDefaults.searchBeginsWith {
            
                return reminder.title.lowercaseString.hasPrefix(searchText.lowercaseString)
            }
            else {
                
                return reminder.title.lowercaseString.containsString(searchText.lowercaseString)
            }
        }

        if searchText != String() {
        
            let filteredShoppingList : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.List.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingCart : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.Cart.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingHistory : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.History.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            groupedShoppingList[Constants.ShoppingListSection.List.rawValue] = filteredShoppingList
            groupedShoppingList[Constants.ShoppingListSection.Cart.rawValue] = filteredShoppingCart
            groupedShoppingList[Constants.ShoppingListSection.History.rawValue] = filteredShoppingHistory
        }
    }
    
    //Save a reminder to the users reminders list
    func saveReminder(reminder : EKReminder){
        
        guard reminderManager.saveReminder(reminder, commit: false) else {
            
            displayError("Your shopping list item could not be saved...")
            
            return
        }
        
        let existingIndex : Int? = shoppingList.indexOf({(existingReminder : EKReminder) in existingReminder.calendarItemExternalIdentifier == reminder.calendarItemExternalIdentifier})
        
        if existingIndex == nil {
            
            shoppingList.append(reminder)
        }
        
        //Re-sort and Reload the list using our local copy
        getShoppingList(shoppingList)
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
    
    override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        
        if shoppingList.count > 0 {
            
            var shoppingListSection : Int = Constants.ShoppingListSection.History.rawValue
            
            let firstItemShoppingListItem : EKReminder = shoppingList[0]
            
            if !firstItemShoppingListItem.completed {
                
                shoppingListSection = Constants.ShoppingListSection.List.rawValue
            }
            else if Utility.itemIsInShoppingCart(firstItemShoppingListItem) {
                
                shoppingListSection = Constants.ShoppingListSection.Cart.rawValue
            }
            
            let indexPath = NSIndexPath(forRow: 0, inSection: shoppingListSection)
            
            remindersTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            
            return false
        }
        
        return true
    }
    
    //Called when we receive the notification from the buttons on the quick sort view
    func scrollToLetter(letter: String) {
        
        //If pressing '+' just scroll to the bottom
        if letter == "+" {
            
            let indexPath = NSIndexPath(forRow: groupedShoppingList[Constants.ShoppingListSection.History.rawValue].count, inSection: Constants.ShoppingListSection.History.rawValue)

            remindersTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        else {
            
            //Scroll to the nearest letter (upwards)
            scrollToNearestLetter(letter)
        }
    }
    
    //Recursive function to find the nearest letter in the alphabet
    func scrollToNearestLetter(letter: String){
        
        //Find any items begining with the specified letter
        var itemsBeginingWith : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.History.rawValue].filter({(reminder : EKReminder) in reminder.completed && reminder.title.hasPrefix(letter)})
        
        //If one exists, find the item first item in the list with that letter
        if itemsBeginingWith.count > 0 {
            
            var index = groupedShoppingList[Constants.ShoppingListSection.History.rawValue].indexOf(itemsBeginingWith[0])
            
            index = (index! == 0) ? 0 : index!-1
            
            let indexPath = NSIndexPath(forRow: index!, inSection: Constants.ShoppingListSection.History.rawValue)
            
            remindersTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        else{
            
            //If no items exist that start with that letter, go back up the alphabet to find one that exists
            let indexOfLetter = Constants.alphabet.indexOf(letter)
            
            if(indexOfLetter > 0) {
                
                scrollToNearestLetter(Constants.alphabet[indexOfLetter!-1])
            }
            else {
                
                //If we are at the begining, scroll to the top
                remindersTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: Constants.ShoppingListSection.History.rawValue), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            }
        }
    }
    
    func setupRightBarButtons(editing : Bool) {
        
        if let containerViewController : ContainerViewController = self.parentViewController as? ContainerViewController {
            
            containerViewController.setupRightBarButtons(editing)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    //To return the number of items that the table view needs to show.
    //We increase it by two for the first blank row and the final "+" (add new item) row
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var sectionCount = groupedShoppingList[section].count
        
        if section == Constants.ShoppingListSection.History.rawValue
            && searchText == String() {
            
            sectionCount += 1
        }
        
        return sectionCount
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return Constants.ShoppingListSections
    }
    
    //To populate each cell's text based on the index into the calendars array, with the extra item at the bottom
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var shoppingListItem : EKReminder?
        
        //Get the cell
        let cell : ShoppingListItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("ReminderCell") as! ShoppingListItemTableViewCell
        
        if(cell.shoppingListItemTextView != nil){
            
            //Keep hold of the table view for each cell so we can do the multi-line refresh
            cell.reminderSortViewController = self
        }
        
        //Based on the settings, set up the auto-capitalisation for the keyboard
        if SettingsUserDefaults.autoCapitalisation{
            
            cell.shoppingListItemTextView.autocapitalizationType = UITextAutocapitalizationType.Words
        }
        else{
            
            cell.shoppingListItemTextView.autocapitalizationType = UITextAutocapitalizationType.Sentences
        }
        
        //Add in the extra item at the bottom
        if indexPath.row == groupedShoppingList[indexPath.section].count && indexPath.section == Constants.ShoppingListSection.History.rawValue {
            
            shoppingListItem = reminderManager.getNewReminder()
            
            //getNewReminder can return nil if the EventStore isn't ready. This happens when the table is first loaded...
            if shoppingListItem == nil{
                
                return ShoppingListItemTableViewCell()
            }
            
            shoppingListItem!.title = Constants.ShoppingListItemTableViewCell.NewItemCell
            shoppingListItem!.completed = false
        }
        
        //Each actual list item...
        else{
            
            shoppingListItem = groupedShoppingList[indexPath.section][indexPath.row]
        }
        
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
    
    //This method is setting which cells can be edited
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        //Don't allow delete of the last blank row...
        if(indexPath.row < groupedShoppingList[indexPath.section].count){
            return true
        }
        
        return false
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return false
    }

    //This method is for the swipe left to delete
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if(indexPath.row < groupedShoppingList[indexPath.section].count){
            
            let shoppingListItem : EKReminder = groupedShoppingList[indexPath.section][indexPath.row]
            
            guard reminderManager.removeReminder(shoppingListItem, commit: false) else {
                
                displayError("Your shopping list item could not be removed...")
                
                return
            }
            
            groupedShoppingList[indexPath.section].removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let headerView : UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
            
            headerView.textLabel?.font = UIFont.systemFontOfSize(12)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        // Set's the height of the Header
        return CGFloat(20)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
         return Constants.ShoppingListSection(rawValue: section)?.description
    }
}

















