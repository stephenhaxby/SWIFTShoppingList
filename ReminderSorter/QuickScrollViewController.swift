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
    
    @IBAction func touchUpInside(sender: UIButton) {
        
        NSNotificationCenter.defaultCenter().postNotificationName("QuickScrollButtonPressed", object: sender)
    }
}
