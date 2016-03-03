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
    
    @IBAction func clearShoppingCartButtonTouchUpInside(sender: AnyObject) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.ClearShoppingList, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arrowAttributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(22.0)]
        let textAttributes = [NSFontAttributeName : UIFont.systemFontOfSize(18.0)]
        
        let backString : NSMutableAttributedString = NSMutableAttributedString(string: "<", attributes: arrowAttributes)
        backString.appendAttributedString(NSMutableAttributedString(string: " Back", attributes: textAttributes))
        
        closeButton.setAttributedTitle(backString, forState: UIControlState.Normal)
    }
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        
        closeInformation()
    }
    
    func closeInformation(){
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}