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
    
    @IBAction func settingsButtonTouchUpInside(sender: AnyObject) {
        
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString){
            
            UIApplication.sharedApplication().openURL(appSettings)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        settingsButton.setTitle("\u{2699}", forState: UIControlState.Normal)
        settingsButton.titleLabel?.font = UIFont.boldSystemFontOfSize(26)
        
        infoButton.setTitle("\u{24D8}", forState: UIControlState.Normal)
        infoButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
    }
}
