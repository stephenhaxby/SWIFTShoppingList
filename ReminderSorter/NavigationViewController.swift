//
//  NavigationViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 17/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class NavigationViewController : UINavigationController {
    
    //All these three methods lock the orentation
    override var shouldAutorotate : Bool {
        
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        
        return UIInterfaceOrientation.portrait
    }
}
