//
//  ContainerViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 13/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class ContainerViewController : UIViewController, UISearchBarDelegate {
    
    var lockTimer : Timer = Timer()
    
    var saveReminderObserver : NSObjectProtocol?    
    var actionOnLockedObserver : NSObjectProtocol?
    var itemBeginEditingObserver : NSObjectProtocol?
    var itemEndEditingObserver : NSObjectProtocol?
    var resetLockObserver : NSObjectProtocol?
    
    var actionOnLockedCounter : Int = 0
    
    @IBOutlet weak var lockButton: UIButton!
    
    var infoButton: UIBarButtonItem!
    
    var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //Custom observer for when a cell / reminder needs to be saved
        saveReminderObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.SaveReminder), object: nil, queue: nil){
            (notification) -> Void in
            
            self.setupRightBarButtons(false)
        }
        
        saveReminderObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ActionOnLocked), object: nil, queue: nil){
            (notification) -> Void in
            
            self.actionOnLocked()
        }


        itemBeginEditingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil, queue: nil){
            (notification) -> Void in
            
            if let isEditing = notification.object as? Bool {
                self.startStopTimer(isEditing)
            }
        }
        
        resetLockObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ResetLock), object: nil, queue: nil){
            (notification) -> Void in
            
            self.resetLock()
        }
    }

    deinit{
        
        if let observer = saveReminderObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.SaveReminder), object: nil)
        }
        
        if let observer = actionOnLockedObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ActionOnLocked), object: nil)
        }

        if let observer = itemBeginEditingObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil)
        }
        
        if let observer = resetLockObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ResetLock), object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searchBar.delegate = self
        
//        let backgroundImage = UIImage(named: "old-white-background")
//        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)

        let background = UIImage(named: "crumpled-white-paper")
        
        var imageView : UIImageView!
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode =  UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = background
        imageView.center = view.center
        view.addSubview(imageView)
        self.view.sendSubview(toBack: imageView)
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.init(red: 0.0, green: 0.5, blue: 1, alpha: 1),
             NSFontAttributeName: Constants.ShoppingListItemFont]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Unlock button
        lockButton.setTitle("\u{1F513}", for: UIControlState())
        lockButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        setupRightBarButtons(false)
        
        setLockTimer()
    }
    
    @IBAction func infoButtonTouchUpInside(_ sender: AnyObject) {
     
        performSegue(withIdentifier: "InfoSegue", sender: sender)
    }
    
    @IBAction func lockButtonTouchUpInside(_ sender: AnyObject) {
        
        lockUnlock()
    }
    
    @IBAction func doneButtonTouchUpInside(_ sender: AnyObject) {
        
        //Find the active / editing Text View and set it to no longer editing
        for controller in self.childViewControllers {
            
            if let reminderSortViewController = controller as? ReminderSortViewController {
                
                for cell in reminderSortViewController.tableView.visibleCells {
                    
                    if let shoppingListItemCell = cell as? ShoppingListItemTableViewCell {
                        
                        if shoppingListItemCell.shoppingListItemTextView.isFirstResponder {
                            
                            shoppingListItemCell.textViewCanResignFirstResponder = false
                            shoppingListItemCell.shoppingListItemTextView.resignFirstResponder()
                        }
                    }
                }
            }
        }
        
        setupRightBarButtons(false)
    }
    
    func startStopTimer(_ stop: Bool) {
        
        if stop {
            lockTimer.invalidate()
        }
        else {
            setLockTimer()
        }
    }

    func setLockTimer() {
        
        if SettingsUserDefaults.autoLockList {
        
            lockTimer = Timer.scheduledTimer(timeInterval: 5.0, target:self, selector: #selector(lockUnlock), userInfo: nil, repeats: false)
        }
    }
    
    func lockUnlock() {
        
        //lock = U+1F512
        //unlock = U+1F513
        
        if lockButton.currentTitle == "\u{1F513}" {
            
            lockButton.setTitle("\u{1F512}", for: UIControlState())
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.InactiveLock), object: true)
            
            lockTimer.invalidate()
        }
        else {
            
            resetLock()
        }
    }
    
    func resetLock(){
        
        lockTimer.invalidate()
        
        lockButton.setTitle("\u{1F513}", for: UIControlState())       
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.InactiveLock), object: false)
        
        setLockTimer()
    }
    
    func setInfoButtonVisible() {
        
        infoButton = UIBarButtonItem(title: "\u{24D8}", style: UIBarButtonItemStyle.plain, target: self, action: #selector(infoButtonTouchUpInside))
        infoButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20)], for: UIControlState())
        
        self.navigationItem.setRightBarButtonItems([infoButton], animated: true)
    }
    
    func setDoneButtonVisible() {
        
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneButtonTouchUpInside))
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)], for: UIControlState())
        
        self.navigationItem.setRightBarButtonItems([doneButton], animated: true)
    }
    
    func actionOnLocked() {
        
        actionOnLockedCounter += 1
        
        if (actionOnLockedCounter >= 3) {
            
            //Display an alert to specify that we couldn't get access
            let errorAlert = UIAlertController(title: "Locked", message: "Unlock your list to complete this action", preferredStyle: UIAlertControllerStyle.alert)
            
            //Add an Ok button to the alert
            errorAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:
                { (action: UIAlertAction!) in
                    
                    self.actionOnLockedCounter = 0
            }))
            
            //Present the alert
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func setupRightBarButtons(_ editing : Bool) {
        
        if editing {
            setDoneButtonVisible()
        }
        else {
            setInfoButtonVisible()
        }
    }
    
    //UISearchBar Delegate methods
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
                
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SearchBarCancel), object: nil)
        
        searchBar.resignFirstResponder()
        searchBar.text = String()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SearchBarTextDidChange), object: searchBar.text)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SetRefreshLock), object: true)
    }

    //This gets called after searchBarCancelButtonClicked
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SetRefreshLock), object: false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
}
