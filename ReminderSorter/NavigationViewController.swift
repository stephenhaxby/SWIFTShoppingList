//
//  NavigationViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 17/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class NavigationViewController : UINavigationController {
    
    override func shouldAutorotate() -> Bool {
        
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask{
        
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        
        return UIInterfaceOrientation.Portrait
    }
}
