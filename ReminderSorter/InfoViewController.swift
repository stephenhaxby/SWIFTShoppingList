//
//  InfoViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 6/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class InfoViewController : UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var shoppingCartExipryDatePicker: UIDatePicker!
    
    @IBOutlet weak var clearShoppingCartButton: UIButton!
    
    var defaults : NSUserDefaults {
        
        get {
            
            return NSUserDefaults.standardUserDefaults()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arrowAttributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(22.0)]
        let textAttributes = [NSFontAttributeName : UIFont.systemFontOfSize(18.0)]
        
        let backString : NSMutableAttributedString = NSMutableAttributedString(string: "<", attributes: arrowAttributes)
        backString.appendAttributedString(NSMutableAttributedString(string: " Back", attributes: textAttributes))
        
        closeButton.setAttributedTitle(backString, forState: UIControlState.Normal)

        if let shoppingCartExpiryTime : NSDate = defaults.objectForKey(Constants.ClearShoppingListExpire) as? NSDate {
            
            shoppingCartExipryDatePicker.date = shoppingCartExpiryTime
        }
        
        clearShoppingCartButton.layer.borderColor = UIColor(red:0.5, green:0.5, blue:0.5, alpha:1.0).CGColor
        clearShoppingCartButton.layer.borderWidth = 1.0
        clearShoppingCartButton.layer.cornerRadius = 5
    }
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        
        closeInformation()
    }
    
    @IBAction func clearShoppingCartButtonTouchUpInside(sender: AnyObject) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.ClearShoppingList, object: nil)
        
        closeInformation()
    }
    
    func closeInformation(){
        
        defaults.setObject(shoppingCartExipryDatePicker.date, forKey: Constants.ClearShoppingListExpire)
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}