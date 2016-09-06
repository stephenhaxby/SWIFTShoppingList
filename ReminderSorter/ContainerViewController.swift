//
//  ContainerViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 13/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class ContainerViewController : UIViewController, UISearchBarDelegate {
    
    let lockTimer : NSTimer = NSTimer()
    
    var saveReminderObserver : NSObjectProtocol?
    
    var actionOnLockedObserver : NSObjectProtocol?
    
    var actionOnLockedCounter : Int = 0
    
    @IBOutlet weak var lockButton: UIButton!
    
    var infoButton: UIBarButtonItem!
    
    var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //Custom observer for when an cell / reminder needs to be saved
        saveReminderObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SaveReminder, object: nil, queue: nil){
            (notification) -> Void in
            
            self.setupRightBarButtons(false)
        }
        
        saveReminderObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.ActionOnLocked, object: nil, queue: nil){
            (notification) -> Void in
            
            self.actionOnLocked()
        }
    }
    
    deinit{
        
        if let observer = saveReminderObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.SaveReminder, object: nil)
        }
        
        if let observer = actionOnLockedObserver{
            
            NSNotificationCenter.defaultCenter().removeObserver(observer, name: Constants.ActionOnLocked, object: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        searchBar.delegate = self
        
//        let backgroundImage = UIImage(named: "old-white-background")
//        self.view.backgroundColor = UIColor(patternImage: backgroundImage!)

        let background = UIImage(named: "crumpled-white-paper")
        
        var imageView : UIImageView!
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode =  UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = background
        imageView.center = view.center
        view.addSubview(imageView)
        self.view.sendSubviewToBack(imageView)
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.init(red: 0.0, green: 0.5, blue: 1, alpha: 1),
             NSFontAttributeName: Constants.ShoppingListItemFont]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Unlock button
        lockButton.setTitle("\u{1F513}", forState: UIControlState.Normal)
        lockButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        
        setupRightBarButtons(false)
        
        //lockTimer = NSTimer.scheduledTimerWithTimeInterval(<#T##ti: NSTimeInterval##NSTimeInterval#>, invocation: <#T##NSInvocation#>, repeats: <#T##Bool#>)
    }
    
    func setInfoButtonVisible() {
        
        infoButton = UIBarButtonItem(title: "\u{24D8}", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(infoButtonTouchUpInside))
        infoButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(20)], forState: UIControlState.Normal)
        
        self.navigationItem.setRightBarButtonItems([infoButton], animated: true)
    }
    
    func setDoneButtonVisible() {
        
        //UIBarButtonSystemItem.
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(doneButtonTouchUpInside))
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(15)], forState: UIControlState.Normal)
        
        self.navigationItem.setRightBarButtonItems([doneButton], animated: true)
    }
    
    @IBAction func infoButtonTouchUpInside(sender: AnyObject) {
     
        performSegueWithIdentifier("InfoSegue", sender: sender)
    }
    
    @IBAction func lockButtonTouchUpInside(sender: AnyObject) {
        
        //lock = U+1F512
        //unlock = U+1F513

        if lockButton.currentTitle == "\u{1F513}" {
        
            lockButton.setTitle("\u{1F512}", forState: UIControlState.Normal)
            
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.InactiveLock, object: true)
        }
        else {
            
            lockButton.setTitle("\u{1F513}", forState: UIControlState.Normal)
            
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.InactiveLock, object: false)
        }
        
        //lockTimer.invalidate()
    }
    
    @IBAction func doneButtonTouchUpInside(sender: AnyObject) {
        
        //Find the active / editing Text View and set it to no longer editing
        for controller in self.childViewControllers {
            
            if let reminderSortViewController = controller as? ReminderSortViewController {
                
                for cell in reminderSortViewController.tableView.visibleCells {
                    
                    if let shoppingListItemCell = cell as? ShoppingListItemTableViewCell {
                        
                        if shoppingListItemCell.shoppingListItemTextView.isFirstResponder() {
                            
                            shoppingListItemCell.shoppingListItemTextView.resignFirstResponder()
                        }
                    }
                }
            }
        }
        
        setupRightBarButtons(false)
    }
    
    func actionOnLocked() {
        
        actionOnLockedCounter += 1
        
        if (actionOnLockedCounter >= 3) {
            
            //Display an alert to specify that we couldn't get access
            let errorAlert = UIAlertController(title: "Locked", message: "Unlock your list to complete this action", preferredStyle: UIAlertControllerStyle.Alert)
            
            //Add an Ok button to the alert
            errorAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:
                { (action: UIAlertAction!) in
                    
                    self.actionOnLockedCounter = 0
            }))
            
            //Present the alert
            self.presentViewController(errorAlert, animated: true, completion: nil)
        }
    }
    
    func setupRightBarButtons(editing : Bool) {
        
        if editing {
            setDoneButtonVisible()
        }
        else {
            setInfoButtonVisible()
        }
    }
    
    //UISearchBar Delegate methods
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
                
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SearchBarCancel, object: nil)
        
        searchBar.resignFirstResponder()
        searchBar.text = String()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SearchBarTextDidChange, object: searchBar.text)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SetRefreshLock, object: true)
    }

    //This gets called after searchBarCancelButtonClicked
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SetRefreshLock, object: false)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
}
