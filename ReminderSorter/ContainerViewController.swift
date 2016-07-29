//
//  ContainerViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 13/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class ContainerViewController : UIViewController, UISearchBarDelegate {

    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var saveReminderObserver : NSObjectProtocol?
    
    //When the settings butto is pressed, open the settings page at the settings for our app
    @IBAction func settingsButtonTouchUpInside(sender: AnyObject) {
        
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString){
            
            UIApplication.sharedApplication().openURL(appSettings)
        }
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //Custom observer for when an cell / reminder needs to be saved
        saveReminderObserver = NSNotificationCenter.defaultCenter().addObserverForName(Constants.SaveReminder, object: nil, queue: nil){
            (notification) -> Void in
            
            self.setupRightBarButtons(false)
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
     
        //Set the text and font of the Settings button (unicode)
        settingsButton.setTitle("\u{2699}", forState: UIControlState.Normal)
        settingsButton.titleLabel?.font = UIFont.boldSystemFontOfSize(26)

        //Set the text and font of the Info button (unicode)
        infoButton.setTitle("\u{24D8}", forState: UIControlState.Normal)
        infoButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        
        setupRightBarButtons(false)
    }
    
    func setupRightBarButtons(editing : Bool) {
        
        infoButton.hidden = editing
        doneButton.hidden = !editing
    }
    
    //UISearchBar Delegate methods
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SetRefreshLock, object: false)
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SearchBarCancel, object: false)
        
        searchBar.resignFirstResponder()
        searchBar.text = String()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SearchBarTextDidChange, object: searchBar.text)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SetRefreshLock, object: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
}
