//
//  ReminderSortViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 15/06/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit
import EventKit
import UserNotifications

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ReminderSortViewController: UITableViewController {
    
    //Outlet for the Table View so we can access it in code
    @IBOutlet var remindersTableView: UITableView!
    
    var refreshLock : NSLock = NSLock()
    
    let reminderManager : iCloudReminderManager = iCloudReminderManager()
    
    var shoppingList = [EKReminder]()
    
    var storedShoppingList = [ShoppingListItem]()
    
    var groupedShoppingList = [[EKReminder]]()
    
    var searchText : String = String()

    var inactiveLock : Bool = false

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
    var inactiveLockObserver : NSObjectProtocol?
    
    var defaults : UserDefaults {
        
        get {
            
            return UserDefaults.standard
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //TODO: Use a loop and the constant value
        
        for _ in 0..<Constants.ShoppingListSections {
            
            groupedShoppingList.append([EKReminder]())
        }
        
        //Used for when the app goes into the background (as we want to commit any changes...)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.reminderSortViewController = self
        
        //Observer for the app for when the event store is changed in the background (or when our app isn't running)
        eventStoreObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.EKEventStoreChanged, object: nil, queue: nil){
            (notification) -> Void in
            
            //<NSRecursiveLock: 0x79e264d0>{locked = YES, thread = 0x2dcf000, recursion count = 2, name = nil}
            
            if self.refreshLock.try() {
            
                //Reload the grid only if there are new items from iCloud that we don't have
                self.conditionalLoadShoppingList() 
                
                self.refreshLock.unlock()
            }
        }
        
        //Observer for when our settings change
        settingsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil){
            (notification) -> Void in
            
            self.refresh()
        }
        
        //Custom observer for when a quickscroll button is pressed
        quickScrollObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.QuickScrollButtonPressed), object: nil, queue: nil){
            (notification) -> Void in
            
            if let quickScrollButton : UIButton = notification.object as? UIButton {

                self.scrollToLetter(quickScrollButton.currentTitle!)
            }
        }
        
        //Custom observer for when an cell / reminder needs to be saved
        saveReminderObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SaveReminder), object: nil, queue: nil){
            (notification) -> Void in
            
            if let reminder : EKReminder = notification.object as? EKReminder{

                self.saveReminder(reminder)
            }
        }
        
        clearShoppingCartObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ClearShoppingList), object: nil, queue: nil){
            (notification) -> Void in
            
            self.clearShoppingCart()
        }
        
        setClearShoppingCartObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SetClearShoppingList), object: nil, queue: nil){
            (notification) -> Void in
            
            self.setClearShoppingCart()
        }
        
        clearShoppingListOnOpenObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ClearShoppingListOnOpen), object: nil, queue: nil){
            (notification) -> Void in
            
            self.CearShoppingCartOnOpen()
        }
        
        searchBarTextDidChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SearchBarTextDidChange), object: nil, queue: nil){
            (notification) -> Void in
            
            if let searchText = notification.object as? String {
                
                self.searchText = searchText

                self.getShoppingList(self.shoppingList)
            }
        }
        
        searchBarCancelObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SearchBarCancel), object: nil, queue: nil){
            (notification) -> Void in
            
            self.startRefreshControl()
            
            self.searchText = String()
            self.getShoppingList(self.shoppingList)
            
            self.endRefreshControl()
        }
        
        setRefreshLock = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SetRefreshLock), object: nil, queue: nil){
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

        inactiveLockObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.InactiveLock), object: nil, queue: nil){
            (notification) -> Void in
            
            if let lock = notification.object as? Bool {
                
                self.inactiveLock = lock
            }
        }
    }
    
    deinit{
        
        //When this class is dealocated we are removing the observers...
        //Don't really need to do this, but it's nice...
        if let observer = eventStoreObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name.EKEventStoreChanged, object: nil)
        }
        
        if let observer = settingsObserver{
            
            NotificationCenter.default.removeObserver(observer, name: UserDefaults.didChangeNotification, object: nil)
        }
        
        if let observer = quickScrollObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.QuickScrollButtonPressed), object: nil)
        }
        
        if let observer = saveReminderObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.SaveReminder), object: nil)
        }
        
        if let observer = clearShoppingCartObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ClearShoppingList), object: nil)
        }
        
        if let observer = setClearShoppingCartObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ClearShoppingList), object: nil)
        }
        
        if let observer = clearShoppingListOnOpenObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ClearShoppingList), object: nil)
        }
        
        if let observer = searchBarTextDidChangeObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.SearchBarTextDidChange), object: nil)
        }
        
        if let observer = searchBarCancelObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.SearchBarCancel), object: nil)
        }
        
        if let observer = searchBarCancelObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.InactiveLock), object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Make it so the screen doesn't turn off
        UIApplication.shared.isIdleTimerDisabled = SettingsUserDefaults.disableScreenLock
        
        //Set the font size of the navigation view controller
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0)]
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        tableView.backgroundColor = UIColor.clear
    }
    
    //Event for pull down to refresh
    @IBAction fileprivate func refresh(_ sender: UIRefreshControl?) {
        
        //Delay for 300 milliseconds then run the refresh / commit
        delay(0.3){
        
            self.commitShoppingList()
        }
    }
    
    func clearPendingShoppingCartNotification() {
        
        if let clearShoppingListNotification : UNNotificationRequest = getPendingShoppingCartNotification() {
            
            // there should be a maximum of one match on UUID
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [clearShoppingListNotification.identifier])
        }
    }
    
    func clearDeliveredShoppingCartNotification() {
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            
            var requests : [UNNotificationRequest] = [UNNotificationRequest]()
            
            for notification in notifications {
                
                requests.append(notification.request)
            }
            
            if let calendarNotification : UNNotificationRequest = self.getClearShoppingCartNotification(forNotifications: requests) {
                
                UNUserNotificationCenter.current().removeDeliveredNotifications(
                    withIdentifiers: [calendarNotification.identifier])
            }
        }
    }
    
    func clearShoppingCart() {
        
        for shoppingListItem in shoppingList {
            
            if shoppingListItem.notes != nil {
                
                shoppingListItem.notes = nil
                
                saveReminder(shoppingListItem)
            }
        }
        
        clearPendingShoppingCartNotification()
        clearDeliveredShoppingCartNotification()
        
        getShoppingList(shoppingList)
    }
    
    func getDeliveredShoppingCartNotification() -> UNNotificationRequest? {
        
        var clearShoppingListNotification : UNNotificationRequest?
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            
            var requests : [UNNotificationRequest] = [UNNotificationRequest]()
            
            for notification in notifications {
                
                requests.append(notification.request)
            }
            
            clearShoppingListNotification = self.getClearShoppingCartNotification(forNotifications: requests)
        }
        
        return clearShoppingListNotification
    }
    
    func getPendingShoppingCartNotification() -> UNNotificationRequest? {
        
        var clearShoppingListNotification : UNNotificationRequest?
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
         
            clearShoppingListNotification = self.getClearShoppingCartNotification(forNotifications: requests)
        }
        
        return clearShoppingListNotification
    }
    
    func getClearShoppingCartNotification(forNotifications requests : [UNNotificationRequest]) -> UNNotificationRequest? {
        
        var clearShoppingListNotification : UNNotificationRequest?
        
        for notification in requests { // loop through notifications...
            
            // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
            if notification.identifier.hasPrefix(Constants.SetClearShoppingList) {
                
                clearShoppingListNotification = notification
                
                break
            }
        }
        
        return clearShoppingListNotification
    }
    
    func setClearShoppingCart() {
        
        clearPendingShoppingCartNotification()
        clearDeliveredShoppingCartNotification()
 
        if let shoppingCartExpiryTime : Date = defaults.object(forKey: Constants.ClearShoppingListExpire) as? Date {
            
            let dateComponents : DateComponents = NSDateManager.getDateComponentsFromDate(shoppingCartExpiryTime)
            
            setClearShoppingCartNotification(forDate: dateComponents)
        }
    }
    
    func setClearShoppingCartNotification(forDate dateComponents : DateComponents) {

        let notification = UNMutableNotificationContent()
        
        notification.categoryIdentifier = Constants.NotificationCategory
        
        let triggerDate : Date = NSDateManager.addHoursAndMinutesToDate(Date(), hours: dateComponents.hour!, Minutes: dateComponents.minute!)
        
        let triggerDateComponents : DateComponents = NSDateManager.getDateComponentsFromDate(triggerDate)
        
        let trigger : UNNotificationTrigger =
            UNCalendarNotificationTrigger(
                dateMatching: triggerDateComponents,
                repeats: false)
        
        //NOTE: As the find/remove methods are async, we could create a new request with this id before the old on has been deleted
        //      thus our new notification could be removed. The find method needs to use has prefix instead...
        let request = UNNotificationRequest(
            identifier: Constants.SetClearShoppingList.appending(UUID().uuidString),
            content: notification,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func CearShoppingCartOnOpen() {
        
        //If the notification fires while we are not active it's not in the list anymore so we need to clear it...
        if getDeliveredShoppingCartNotification() != nil {
            
            clearShoppingCart()
        }
    }
    
    func commitShoppingList() {
        
        //Add a blank reminder to help trigger an iCloud sync
        if let blankReminder : EKReminder = self.reminderManager.addReminder("", commit: false) {
            
            //Commit all updated items yet to be committed
            let _ = self.reminderManager.commit()
            
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
            
            DispatchQueue.main.async { () -> Void in
            
                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
            
            //shoppingListTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
        }
    }
    
    //Delay function to delay the execution of something for a number of seconds
    func delay(_ delay: Double, closure: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: closure
        )
    }
    
    //Only update the shopping list if items have been updated
    func conditionalLoadShoppingList(_ iCloudShoppingList : [EKReminder]) {

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
                let updatedItemIndex : Int? = updatedShoppingList.index(where: {(reminder : EKReminder) in reminder.calendarItemExternalIdentifier == currentItem.calendarItemExternalIdentifier})
                
                //If the item exists, check if we need to update our local copy
                if updatedItemIndex != nil {

                    let updatedItem : EKReminder = updatedShoppingList[updatedItemIndex!]

                    if currentItem.completed != updatedItem.isCompleted
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
            
            if !refresh.isRefreshing {
             
                refresh.beginRefreshing()
            }
        }
    }
    
    func endRefreshControl(){
        
        if let refresh = refreshControl{
            
            if refresh.isRefreshing {
            
                refresh.endRefreshing()
            }
        }
    }
    
    func endRefreshControl(_ sender: UIRefreshControl?){
        
        if let refresh = sender{
            
            refresh.endRefreshing()
        }
    }
    
    //Once access is granted to the reminders list
    func requestedAccessToReminders(_ status : Bool){
        
        if status {
            
            loadShoppingList()
        }
        else{
            
            displayError("Please allow Shopping to access 'Reminders'...")
        }
        
        endRefreshControl()
    }
    
    //Once the reminders have been loaded from iCloud
    func getShoppingList(_ iCloudShoppingList : [EKReminder]){
        
        createGroupedShoppingList(iCloudShoppingList)
        
        storedShoppingList = [ShoppingListItem]()
        
        //Create backup for conditional loading
        for shoppingListItem in self.shoppingList {
                    
            let storedShoppingListItem : ShoppingListItem = ShoppingListItem()
            storedShoppingListItem.calendarItemExternalIdentifier = shoppingListItem.calendarItemExternalIdentifier
            storedShoppingListItem.title = shoppingListItem.title
            storedShoppingListItem.completed = shoppingListItem.isCompleted
            storedShoppingListItem.notes = shoppingListItem.notes
            
            self.storedShoppingList.append(storedShoppingListItem)
        }

        filterGroupedShoppingList()

        //As we a in another thread, post back to the main thread so we can update the UI
        DispatchQueue.main.async { () -> Void in

            if let shoppingListTable = self.tableView {

                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
        }
    }

    func createGroupedShoppingList(_ iCloudShoppingList : [EKReminder]) {
        
        //var shoppingList = [EKReminder]() // All reminders from the store
        
        //var storedShoppingList = [ShoppingListItem]() // BACKUP
        
        //var groupedShoppingList = [[EKReminder]]() // Datasource
        
        //Small function for sorting reminders
        func reminderSort(_ reminder1: EKReminder, reminder2: EKReminder) -> Bool {
            
            return reminder1.title.lowercased() < reminder2.title.lowercased()
        }
        
        //Find all items that are NOT completed
        var itemsToGet : [EKReminder] = iCloudShoppingList.filter({(reminder : EKReminder) in !reminder.isCompleted})
        
        //Find all items that are in the shopping cart
        var itemsGot : [EKReminder] = iCloudShoppingList.filter( {
            (reminder : EKReminder) in
            
            return Utility.itemIsInShoppingCart(reminder)
        })
        
        //Find all items that ARE completed
        var completedItems : [EKReminder] = iCloudShoppingList.filter( {
            (reminder : EKReminder) in
            
            return reminder.isCompleted && !Utility.itemIsInShoppingCart(reminder)
        })
        
        //If the setting specify alphabetical sorting of incomplete items
        if SettingsUserDefaults.alphabeticalSortIncomplete {
            
            itemsToGet = itemsToGet.sorted(by: reminderSort)
        }
        
        if SettingsUserDefaults.alphabeticalSortIncomplete {
            
            itemsGot = itemsGot.sorted(by: reminderSort)
        }
        
        //If the settings specify alphabetical sorting of complete items
        if SettingsUserDefaults.alphabeticalSortComplete {
            
            completedItems = completedItems.sorted(by: reminderSort)
        }
        
        groupedShoppingList[Constants.ShoppingListSection.list.rawValue] = itemsToGet
        groupedShoppingList[Constants.ShoppingListSection.cart.rawValue] = itemsGot
        groupedShoppingList[Constants.ShoppingListSection.history.rawValue] = completedItems
        
        //Join the two lists from above
        shoppingList = itemsToGet + itemsGot + completedItems
    }
    
    func filterGroupedShoppingList() {

        func reminderTitleContains(_ reminder : EKReminder, searchText : String) -> Bool {
   
            if SettingsUserDefaults.searchBeginsWith {
            
                return reminder.title.lowercased().hasPrefix(searchText.lowercased())
            }
            else {
                
                return reminder.title.lowercased().contains(searchText.lowercased())
            }
        }

        if searchText != String() {
        
            let filteredShoppingList : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.list.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingCart : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.cart.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingHistory : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.history.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            groupedShoppingList[Constants.ShoppingListSection.list.rawValue] = filteredShoppingList
            groupedShoppingList[Constants.ShoppingListSection.cart.rawValue] = filteredShoppingCart
            groupedShoppingList[Constants.ShoppingListSection.history.rawValue] = filteredShoppingHistory
        }
    }
    
    //Save a reminder to the users reminders list
    func saveReminder(_ reminder : EKReminder){
        
        guard reminderManager.saveReminder(reminder, commit: false) else {
            
            displayError("Your shopping list item could not be saved...")
            
            return
        }
        
        let existingIndex : Int? = shoppingList.index(where: {(existingReminder : EKReminder) in existingReminder.calendarItemExternalIdentifier == reminder.calendarItemExternalIdentifier})
        
        if existingIndex == nil {
            
            shoppingList.append(reminder)
        }
        
        //Re-sort and Reload the list using our local copy
        getShoppingList(shoppingList)
    }

    func displayError(_ message : String){
        
        //Display an alert to specify that we couldn't get access
        let errorAlert = UIAlertController(title: "Error!", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //Add an Ok button to the alert
        errorAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:
            { (action: UIAlertAction!) in
                
        }))
        
        //Present the alert
        self.present(errorAlert, animated: true, completion: nil)
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        
        if shoppingList.count > 0 {
            
            var shoppingListSection : Int = Constants.ShoppingListSection.history.rawValue
            
            let firstItemShoppingListItem : EKReminder = shoppingList[0]
            
            if !firstItemShoppingListItem.isCompleted {
                
                shoppingListSection = Constants.ShoppingListSection.list.rawValue
            }
            else if Utility.itemIsInShoppingCart(firstItemShoppingListItem) {
                
                shoppingListSection = Constants.ShoppingListSection.cart.rawValue
            }
            
            let indexPath = IndexPath(row: 0, section: shoppingListSection)
            
            remindersTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            
            return false
        }
        
        return true
    }
    
    //Called when we receive the notification from the buttons on the quick sort view
    func scrollToLetter(_ letter: String) {
        
        //If pressing '+' just scroll to the bottom
        if letter == "+" {
            
            let indexPath = IndexPath(row: groupedShoppingList[Constants.ShoppingListSection.history.rawValue].count, section: Constants.ShoppingListSection.history.rawValue)

            remindersTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
        }
        else {
            
            //Scroll to the nearest letter (upwards)
            scrollToNearestLetter(letter)
        }
    }
    
    //Recursive function to find the nearest letter in the alphabet
    func scrollToNearestLetter(_ letter: String){
        
        //Find any items begining with the specified letter
        var itemsBeginingWith : [EKReminder] = groupedShoppingList[Constants.ShoppingListSection.history.rawValue].filter({(reminder : EKReminder) in reminder.isCompleted && reminder.title.hasPrefix(letter)})
        
        //If one exists, find the item first item in the list with that letter
        if itemsBeginingWith.count > 0 {
            
            var index = groupedShoppingList[Constants.ShoppingListSection.history.rawValue].index(of: itemsBeginingWith[0])
            
            index = (index! == 0) ? 0 : index!-1
            
            let indexPath = IndexPath(row: index!, section: Constants.ShoppingListSection.history.rawValue)
            
            remindersTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
        }
        else{
            
            //If no items exist that start with that letter, go back up the alphabet to find one that exists
            let indexOfLetter = Constants.alphabet.index(of: letter)
            
            if(indexOfLetter > 0) {
                
                scrollToNearestLetter(Constants.alphabet[indexOfLetter!-1])
            }
            else {
                
                //If we are at the begining, scroll to the top
                remindersTableView.scrollToRow(at: IndexPath(row: 0, section: Constants.ShoppingListSection.history.rawValue), at: UITableViewScrollPosition.top, animated: true)
            }
        }
    }
    
    func setupRightBarButtons(_ editing : Bool) {
        
        if let containerViewController : ContainerViewController = self.parent as? ContainerViewController {
            
            containerViewController.setupRightBarButtons(editing)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    //To return the number of items that the table view needs to show.
    //We increase it by two for the first blank row and the final "+" (add new item) row
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var sectionCount = groupedShoppingList[section].count
        
        if section == Constants.ShoppingListSection.history.rawValue
            && searchText == String() {
            
            sectionCount += 1
        }
        
        return sectionCount
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return Constants.ShoppingListSections
    }
    
    //To populate each cell's text based on the index into the calendars array, with the extra item at the bottom
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var shoppingListItem : EKReminder?
        
        //Get the cell
        let cell : ShoppingListItemTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell") as! ShoppingListItemTableViewCell
        
        if(cell.shoppingListItemTextView != nil){
            
            //Keep hold of the table view for each cell so we can do the multi-line refresh
            cell.reminderSortViewController = self
        }
        
        //Based on the settings, set up the auto-capitalisation for the keyboard
        if SettingsUserDefaults.autoCapitalisation{
            
            cell.shoppingListItemTextView.autocapitalizationType = UITextAutocapitalizationType.words
        }
        else{
            
            cell.shoppingListItemTextView.autocapitalizationType = UITextAutocapitalizationType.sentences
        }
        
        //Add in the extra item at the bottom
        if (indexPath as NSIndexPath).row == groupedShoppingList[(indexPath as NSIndexPath).section].count && (indexPath as NSIndexPath).section == Constants.ShoppingListSection.history.rawValue {
            
            shoppingListItem = reminderManager.getNewReminder()
            
            //getNewReminder can return nil if the EventStore isn't ready. This happens when the table is first loaded...
            if shoppingListItem == nil{
                
                return ShoppingListItemTableViewCell()
            }
            
            shoppingListItem!.title = Constants.ShoppingListItemTableViewCell.NewItemCell
            shoppingListItem!.isCompleted = false
        }
        
        //Each actual list item...
        else{
            
            shoppingListItem = groupedShoppingList[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        //Don't allow delete of the last blank row...
        if((indexPath as NSIndexPath).row < groupedShoppingList[(indexPath as NSIndexPath).section].count){
            return true
        }
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }

    //This method is for the swipe left to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if(inactiveLock) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ActionOnLocked), object: nil)
        }

        if(!inactiveLock && (indexPath as NSIndexPath).row < groupedShoppingList[(indexPath as NSIndexPath).section].count){
            
            let shoppingListItem : EKReminder = groupedShoppingList[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            
            guard reminderManager.removeReminder(shoppingListItem, commit: false) else {
                
                displayError("Your shopping list item could not be removed...")
                
                return
            }
            
            groupedShoppingList[(indexPath as NSIndexPath).section].remove(at: (indexPath as NSIndexPath).row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let headerView : UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
            
            headerView.textLabel?.font = UIFont.systemFont(ofSize: 12)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        // Set's the height of the Header
        return CGFloat(20)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
         return Constants.ShoppingListSection(rawValue: section)?.description
    }
}

















