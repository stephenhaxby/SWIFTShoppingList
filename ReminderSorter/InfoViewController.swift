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
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        //TODO: Swipe left to go back...
        
        let arrowAttributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(22.0)]
        let textAttributes = [NSFontAttributeName : UIFont.systemFontOfSize(18.0)]
        
        let backString : NSMutableAttributedString = NSMutableAttributedString(string: "<", attributes: arrowAttributes)
        backString.appendAttributedString(NSMutableAttributedString(string: " Back", attributes: textAttributes))
        
        closeButton.setAttributedTitle(backString, forState: UIControlState.Normal)

        
        //scrollView.delegate = self
        
        //scrollView.showsHorizontalScrollIndicator = false
        
//        let screenSize: CGRect = UIScreen.mainScreen().bounds
//        
//        let scrollSize = CGSizeMake(screenSize.width, screenSize.height)
//        scrollView.contentSize = scrollSize
    }
    
//    override func viewWillAppear(animated: Bool) {
//        
//        let screenSize: CGRect = UIScreen.mainScreen().bounds
//        
//        let scrollSize = CGSizeMake(screenSize.width, screenSize.height)
//        scrollView.contentSize = scrollSize
//    }
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        
        closeInformation()
    }
    
    func closeInformation(){
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}