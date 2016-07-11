//
//  ContainerViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 13/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class ContainerViewController : UIViewController {

    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var doneButton: UIButton!
    
    //When the settings butto is pressed, open the settings page at the settings for our app
    @IBAction func settingsButtonTouchUpInside(sender: AnyObject) {
        
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString){
            
            UIApplication.sharedApplication().openURL(appSettings)
        }
    }
    
    @IBAction func doneButtonTouchUpInside(sender: AnyObject) {
        
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
}
