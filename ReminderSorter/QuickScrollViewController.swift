//
//  QuickScrollViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 15/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class QuickScrollViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
     
        view.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:0.4)
    }
    
    @IBAction func touchUpInside(sender: UIButton) {
        
        //When any of the alphabet buttons are clicked, post the notification along with the button that was pressed
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.QuickScrollButtonPressed, object: sender)
    }
}
