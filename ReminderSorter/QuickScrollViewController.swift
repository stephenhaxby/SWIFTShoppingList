//
//  QuickScrollViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 15/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class QuickScrollViewController : UIViewController {
   
    var itemBeginEditingObserver : NSObjectProtocol?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        itemBeginEditingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil, queue: nil){
            (notification) -> Void in
            
            if let isEditing = notification.object as? Bool {
                
                if isEditing {
                    
                    self.disableQuickScrollButtons(self.view.subviews)
                }
                else {
                    
                    self.enableQuickScrollButtons(self.view.subviews)
                }
            }
        }
    }
    
    deinit {
        
        if let observer = itemBeginEditingObserver{
            
            NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: Constants.ItemEditing), object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setQuickLinkButtonFont(self.view.subviews)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        view.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:0.4)
    }
    
    @IBAction func touchUpInside(_ sender: UIButton) {
        
        //When any of the alphabet buttons are clicked, post the notification along with the button that was pressed
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.QuickScrollButtonPressed), object: sender)
    }
    
    //Recursive method to set every buttons font
    func setQuickLinkButtonFont(_ views: [UIView]) {
        
        for subview in views as [UIView] {
            
            setQuickLinkButtonFont(subview.subviews)
            
            if let button = subview as? UIButton {
                
                button.titleLabel?.font = Constants.QuickJumpListItemFont
            }
        }
    }
    
    func enableQuickScrollButtons(_ views: [UIView]) {
        
        for subview in views as [UIView] {
            
            enableQuickScrollButtons(subview.subviews)
            
            if let button = subview as? UIButton {
                
                button.isEnabled = true
            }
        }
    }
    
    func disableQuickScrollButtons(_ views: [UIView]) {
        
        for subview in views as [UIView] {
            
            disableQuickScrollButtons(subview.subviews)
            
            if let button = subview as? UIButton {
                
                button.isEnabled = false
            }
        }
    }
}
