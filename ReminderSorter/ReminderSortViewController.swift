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

//Override for the less than compare operator to handle nils
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

//Override for the greater than than compare operator to handle nils
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

extension Array where Element: Equatable {
    
    mutating func remove(object: Element) {
        if let itemIndex = index(of: object) {
            remove(at: itemIndex)
        }
    }
}

class ReminderSortViewController: UITableViewController {
    
    //Outlet for the Table View so we can access it in code
    @IBOutlet var remindersTableView: UITableView!
    
    var storageFacade : StorageFacadeProtocol {
        
        get {
            
             return (UIApplication.shared.delegate as! AppDelegate).AppStorageFacade
        }
    }
    
    var refreshLock : NSLock = NSLock()
       
    var shoppingList = [ShoppingListItem]() // All reminders from the store
    
    var storedShoppingList = [ShoppingListItem]() // BACKUP
    
    var groupedShoppingList = [[ShoppingListItem]]() // Datasource
    
    var searchText : String = String()

    var inactiveLock : Bool = false

    var eventStoreObserver : NSObjectProtocol?
    var settingsObserver : NSObjectProtocol?
    var quickScrollObserver : NSObjectProtocol?
    var saveReminderObserver : NSObjectProtocol?
    var clearShoppingCartObserver : NSObjectProtocol?
    var clearShopingCartOnOpenObserver : NSObjectProtocol?
    var searchBarTextDidChangeObserver : NSObjectProtocol?
    var searchBarCancelObserver : NSObjectProtocol?
    var setRefreshLock : NSObjectProtocol?
    var inactiveLockObserver : NSObjectProtocol?
    var reloadListObserver : NSObjectProtocol?
    
    var defaults : UserDefaults {
        
        get {
            
            return UserDefaults.standard
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Setup the three sections / groups for the shopping list 
        for _ in 0..<Constants.ShoppingListSections {
            
            groupedShoppingList.append([ShoppingListItem]())
        }
        
        reloadListObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ReloadList), object: nil, queue: nil){
            (notification) -> Void in
            
            if self.refreshLock.try() {
                
                self.loadShoppingList()
                
                self.refreshLock.unlock()
            }
        }
        
        //Observer for the app for when the event store is changed in the background (or when our app isn't running (iCloud only))
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
            
            self.storageOptionChanged()
            
            self.loadShoppingList()
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
            
            if let reminder : ShoppingListItem = notification.object as? ShoppingListItem {

                if reminder.title != Constants.ShoppingListItemTableViewCell.NewItemCell {
                
                    self.saveReminder(reminder)
                }
            }
        }
        
        clearShoppingCartObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ClearShoppingList), object: nil, queue: nil){
            (notification) -> Void in
            
            if self.refreshLock.try() {
                
                self.clearShoppingCart()
                
                self.refreshLock.unlock()
            }
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
            
            self.searchText = String()
            self.getShoppingList(self.shoppingList)
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
                
                self.refreshLock.unlock()
                self.inactiveLock = lock
            }
        }
    }
    
    deinit{
        
        //When this class is dealocated we are removing the observers...
        //Don't really need to do this, but it's nice...
        if let observer = reloadListObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ReloadList), object: nil)
        }
        
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
        //startRefreshControl()
        
        //Request access to the users reminders list; call 'requestedAccessToReminders' when done
        //reminderManager.requestAccessToReminders(requestedAccessToReminders)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        tableView.backgroundColor = UIColor.clear
    }
    
    //Event for pull down to refresh
    @IBAction fileprivate func refresh(_ sender: UIRefreshControl?) {
        
        //Delay for 300 milliseconds then run the refresh / commit
        delay(0.3){
        
            self.forceRefreshShoppingList()
        }
    }
    
    func storageOptionChanged() {
        
        (UIApplication.shared.delegate as! AppDelegate).setStorageType()
    }
    
    func clearShoppingCart() {
        
        storageFacade.clearShoppingList {
            success in
            
            if !success {
                
                self.displayError("Your shopping list item could not be saved...")
            }
            
            self.loadShoppingList()
        }
    }
    
//    func clearShoppingCart() {
//        
//        let shoppingCartItems : [ShoppingListItem] = shoppingList.filter({(reminder : ShoppingListItem) in Utility.itemIsInShoppingCart(reminder)})
//        
//        let dispatchGroup = DispatchGroup()
//        
//        for shoppingCartItem in shoppingCartItems {
//            
//            dispatchGroup.enter()
//            
//            shoppingCartItem.notes = nil
//            
//            storageFacade.createOrUpdateShoppingListItem(shoppingCartItem) { success in
//                
//                dispatchGroup.leave()
//                
//                guard success else {
//                    
//                    self.displayError("Your shopping list item could not be saved...")
//                    
//                    return
//                }
//            }
//        }
//        
//        dispatchGroup.notify(queue: .main){
//            
//            self.loadShoppingList()
//        }
//    }
    
    func forceRefreshShoppingList() {
        
        storageFacade.forceUpdateShoppingList()
        
        loadShoppingList()
    }
    
    //Gets the shopping list from the manager and reloads the table
    func loadShoppingList(){
        
        storageFacade.getShoppingListItems(getShoppingList)
    }
    
    //Gets the shopping list from the manager and reloads the table ONLY if there are differing items
    func conditionalLoadShoppingList() {
    
        storageFacade.getShoppingListItems(conditionalLoadShoppingList)
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
    func conditionalLoadShoppingList(_ iCloudShoppingList : [ShoppingListItem]) {

        //Filter out any blank items
        let updatedShoppingList : [ShoppingListItem] = iCloudShoppingList.filter({(reminder : ShoppingListItem) in reminder.title != ""})
        
        let storedShoppingListSet : Set<ShoppingListItem> = Set(storedShoppingList.map({$0}))
        var tempStoredShoppingListSet : Set<ShoppingListItem> = Set(storedShoppingList.map({$0}))
        
        var updatedShoppingListSet : Set<ShoppingListItem> = Set(updatedShoppingList.map({$0}))
        let tempUpdatedShoppingListSet : Set<ShoppingListItem> = Set(updatedShoppingList.map({$0}))
        
        //Find items that are not in each list
        updatedShoppingListSet.subtract(storedShoppingListSet)
        tempStoredShoppingListSet.subtract(tempUpdatedShoppingListSet)

        var reloadShoppingList = updatedShoppingListSet.count > 0 || storedShoppingListSet.count > 0
        
        //Add the missing items from iCloud
        storedShoppingList.append(contentsOf: updatedShoppingListSet)
        
        //Remove items deleted from iCloud
        for item in tempStoredShoppingListSet {
            
            storedShoppingList.remove(object: item)
        }
        
        //Loop for all items in our local list
        for i in 0 ..< storedShoppingList.count {

            //Get the local item
            let currentItem : ShoppingListItem = storedShoppingList[i]

            //Find a matching item by ID in the iCloud list
            let updatedItemIndex : Int? = updatedShoppingList.index(where: {(reminder : ShoppingListItem) in reminder.calendarItemExternalIdentifier == currentItem.calendarItemExternalIdentifier})

            //If the item exists, check if we need to update our local copy
            if updatedItemIndex != nil {

                let updatedItem : ShoppingListItem = updatedShoppingList[updatedItemIndex!]

                if currentItem.completed != updatedItem.completed {
                
                    let currentItemDate : Date? = Utility.getDateFromNotes(currentItem.notes)
                    let updatedItemDate : Date? = Utility.getDateFromNotes(updatedItem.notes)

                    //If iCloud version is newer
                    if (currentItemDate == nil && updatedItemDate != nil) //Case to handle items having their notes cleared or modified in the Reminders app (clear trolley adds an "*")
                        || (currentItemDate != nil
                            && updatedItemDate != nil
                            && NSDateManager.dateIsBeforeDate(currentItemDate!, date2: updatedItemDate!))
                    {
                        currentItem.completed = updatedItem.completed
                        reloadShoppingList = true
                    }
                }
            }
        }
        
        if reloadShoppingList {
            getShoppingList(updatedShoppingList)
        }
    }
    
    func updateCurrentItemFrom(_ currentItem: ShoppingListItem, updatedItem : ShoppingListItem) {
        
        currentItem.completed = updatedItem.completed
        currentItem.title = updatedItem.title
        currentItem.notes = updatedItem.notes
    }
    
    func endRefreshControl(){
        
        if let refresh = refreshControl{
            
            if refresh.isRefreshing {
            
                refresh.endRefreshing()
            }
        }
    }
    
    //Once the reminders have been loaded from iCloud
    func getShoppingList(_ iCloudShoppingList : [ShoppingListItem]){
        
        createGroupedShoppingList(iCloudShoppingList)
        
        storedShoppingList = [ShoppingListItem]()
        
        //Create backup for conditional loading
        for shoppingListItem in shoppingList {
                    
            let storedShoppingListItem : ShoppingListItem = ShoppingListItem()
            storedShoppingListItem.calendarItemExternalIdentifier = shoppingListItem.calendarItemExternalIdentifier
            storedShoppingListItem.title = shoppingListItem.title
            storedShoppingListItem.completed = shoppingListItem.completed
            storedShoppingListItem.notes = shoppingListItem.notes
            
            storedShoppingList.append(storedShoppingListItem)
        }

        filterGroupedShoppingList()

        //As we a in another thread, post back to the main thread so we can update the UI
        DispatchQueue.main.async { () -> Void in

            self.endRefreshControl()
            
            if let shoppingListTable = self.tableView {

                //Request a reload of the Table
                shoppingListTable.reloadData()
            }
        }
    }

    func createGroupedShoppingList(_ iCloudShoppingList : [ShoppingListItem]) {
        
        //var shoppingList = [ShoppingListItem]() // All reminders from the store
        
        //var storedShoppingList = [ShoppingListItem]() // BACKUP
        
        //var groupedShoppingList = [[ShoppingListItem]]() // Datasource
        
        //Small function for sorting reminders
        func reminderSort(_ reminder1: ShoppingListItem, reminder2: ShoppingListItem) -> Bool {
            
            return reminder1.title.lowercased() < reminder2.title.lowercased()
        }
        
        //Find all items that are NOT completed
        var itemsToGet : [ShoppingListItem] = iCloudShoppingList.filter({(reminder : ShoppingListItem) in !reminder.completed})
        
        //Find all items that are in the shopping cart
        var itemsGot : [ShoppingListItem] = iCloudShoppingList.filter( {
            (reminder : ShoppingListItem) in
            
            return Utility.itemIsInShoppingCart(reminder)
        })
        
        //Find all items that ARE completed
        var completedItems : [ShoppingListItem] = iCloudShoppingList.filter( {
            (reminder : ShoppingListItem) in
            
            return reminder.completed && !Utility.itemIsInShoppingCart(reminder)
        })
        
        //Alphabetical sorting of incomplete items
        itemsToGet = itemsToGet.sorted(by: reminderSort)

        //Alphabetical sorting of trolley items
        itemsGot = itemsGot.sorted(by: reminderSort)
        
        //Alphabetical sorting of complete items
        completedItems = completedItems.sorted(by: reminderSort)
        
        groupedShoppingList[Constants.ShoppingListSection.list.rawValue] = itemsToGet
        groupedShoppingList[Constants.ShoppingListSection.cart.rawValue] = itemsGot
        groupedShoppingList[Constants.ShoppingListSection.history.rawValue] = completedItems
        
        //Join the two lists from above
        shoppingList = itemsToGet + itemsGot + completedItems
    }
    
    func filterGroupedShoppingList() {

        func reminderTitleContains(_ reminder : ShoppingListItem, searchText : String) -> Bool {
   
            if SettingsUserDefaults.searchBeginsWith {
            
                return reminder.title.lowercased().hasPrefix(searchText.lowercased())
            }
            else {
                
                return reminder.title.lowercased().contains(searchText.lowercased())
            }
        }

        if searchText != String() {
        
            let filteredShoppingList : [ShoppingListItem] = groupedShoppingList[Constants.ShoppingListSection.list.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingCart : [ShoppingListItem] = groupedShoppingList[Constants.ShoppingListSection.cart.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            let filteredShoppingHistory : [ShoppingListItem] = groupedShoppingList[Constants.ShoppingListSection.history.rawValue].filter{reminder in reminderTitleContains(reminder, searchText : searchText)}
            
            groupedShoppingList[Constants.ShoppingListSection.list.rawValue] = filteredShoppingList
            groupedShoppingList[Constants.ShoppingListSection.cart.rawValue] = filteredShoppingCart
            groupedShoppingList[Constants.ShoppingListSection.history.rawValue] = filteredShoppingHistory
        }
    }
    
    //Save a reminder to the users reminders list
    func saveReminder(_ reminder : ShoppingListItem){

        storageFacade.createOrUpdateShoppingListItem(reminder) { success in
         
            guard success else {
                
                self.displayError("Your shopping list item could not be saved...")
                
                return
            }
            
            self.loadShoppingList()
        }
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
            
            let firstItemShoppingListItem : ShoppingListItem = shoppingList[0]
            
            if !firstItemShoppingListItem.completed {
                
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
        var itemsBeginingWith : [ShoppingListItem] = groupedShoppingList[Constants.ShoppingListSection.history.rawValue].filter({(reminder : ShoppingListItem) in reminder.completed && reminder.title.hasPrefix(letter)})
        
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
        
        var shoppingListItem : ShoppingListItem?
        
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
            
            shoppingListItem = ShoppingListItem()            
            shoppingListItem!.title = Constants.ShoppingListItemTableViewCell.NewItemCell
            shoppingListItem!.completed = false
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

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {

        if let tableCell : ShoppingListItemTableViewCell = tableView.cellForRow(at: indexPath) as? ShoppingListItemTableViewCell,
            tableCell.isShoppingListItemEditing(){
            
            return .none
        }
        
        return .delete
    }
    
    //This method is for the swipe left to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if(inactiveLock) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ActionOnLocked), object: nil)
        }

        if(!inactiveLock && (indexPath as NSIndexPath).row < groupedShoppingList[(indexPath as NSIndexPath).section].count){
            
            let shoppingListItem : ShoppingListItem = groupedShoppingList[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            
            storageFacade.removeShoppingListItem(shoppingListItem, saveSuccess : save)
            
            groupedShoppingList[(indexPath as NSIndexPath).section].remove(at: (indexPath as NSIndexPath).row)
            
            if let shoppingListIndex = shoppingList.index(of: shoppingListItem) {
             
                shoppingList.remove(at: shoppingListIndex)
            }
            
            
            
            //reminderSortViewController.tableView.isScrollEnabled
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func save(success : Bool) {
        
        guard success else {
            
            displayError("Your shopping list item could not be removed...")
            
            return
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

















