//
//  InfoViewController.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 6/10/2015.
//  Copyright © 2015 Stephen Haxby. All rights reserved.
//

import UIKit

class InfoViewController : UIViewController {
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var shoppingCartExipryDatePicker: UIDatePicker!
    
    @IBOutlet weak var clearShoppingCartButton: UIButton!
    
    var originalDate : Date = NSDateManager.currentDateWithHour(2, minute: 0, second: 0)
    
    var defaults : UserDefaults {
        
        get {
            
            return UserDefaults.standard
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the text and font of the Settings button (unicode)
        settingsButton.setTitle("\u{2699}", for: UIControlState())
        settingsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        
        let arrowAttributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 22.0)]
        let textAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 18.0)]
        
        let backString : NSMutableAttributedString = NSMutableAttributedString(string: "<", attributes: arrowAttributes)
        backString.append(NSMutableAttributedString(string: " Back", attributes: textAttributes))
        
        closeButton.setAttributedTitle(backString, for: UIControlState())

        if let shoppingCartExpiryTime : Date = defaults.object(forKey: Constants.ClearShoppingListExpire) as? Date {
            
            shoppingCartExipryDatePicker.date = shoppingCartExpiryTime
        }
        else {
            
            shoppingCartExipryDatePicker.date = originalDate
        }
        
        clearShoppingCartButton.layer.borderColor = UIColor(red:0.5, green:0.5, blue:0.5, alpha:1.0).cgColor
        clearShoppingCartButton.layer.borderWidth = 1.0
        clearShoppingCartButton.layer.cornerRadius = 5
        
        originalDate = shoppingCartExipryDatePicker.date
    }
    
    //When the settings butto is pressed, open the settings page at the settings for our app
    @IBAction func settingsButtonTouchUpInside(_ sender: AnyObject) {
        
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString){
            
            UIApplication.shared.open(appSettings, options: [:])
        }
    }
    
    @IBAction func closeButtonTouchUpInside(_ sender: AnyObject) {
        
        closeInformation(){}
    }
    
    @IBAction func clearShoppingCartButtonTouchUpInside(_ sender: AnyObject) {
        
        closeInformation() {
        
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ClearShoppingList), object: nil)
        }
    }
    
    func closeInformation(completionBlock : @escaping (() -> Void)){
        
        if defaults.object(forKey: Constants.ClearShoppingListExpire) == nil
            || originalDate != shoppingCartExipryDatePicker.date {
        
            defaults.set(shoppingCartExipryDatePicker.date, forKey: Constants.ClearShoppingListExpire)
        }
        
        presentingViewController?.dismiss(animated: true, completion: completionBlock)
    }
}
