//
//  AppDelegate.swift
//  ReminderSorter
//
//  Created by Stephen Haxby on 15/06/2015.
//  Copyright (c) 2015 Stephen Haxby. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    //Gets the managed object context for core data (as a singleton)
    private let coreDataContext = CoreDataManager.context()
    
    private var storageType : Constants.StorageType = Constants.StorageType.iCloudReminders
    
    private var storageFacade : StorageFacadeProtocol?
    
    var window: UIWindow?

    var AppStorageFacade : StorageFacadeProtocol {
        
        get{
            
            return storageFacade!
        }
    }
    
    override init() {
        super.init()
        
        setStorageType()
    }
    
    func setStorageType() {
        
        //If the storage type changes, or storageFacade is null, run the factory method
        let newStorageType = (SettingsUserDefaults.storageICloudReminders) ? Constants.StorageType.iCloudReminders : Constants.StorageType.local
        
        if storageType != newStorageType || storageFacade == nil {
            
            storageType = (SettingsUserDefaults.storageICloudReminders) ? Constants.StorageType.iCloudReminders : Constants.StorageType.local
            storageFacade = StorageFacadeFactory.getStorageFacade(storageType, managedObjectContext: coreDataContext)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.classForCoder() as! UIAppearanceContainer.Type]).setTitleTextAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18)], for: .normal)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let _ = storageFacade?.commit()
        
        if storageType == Constants.StorageType.local {
            
            CoreDataManager.saveContext(context: coreDataContext)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
               
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ResetLock), object: self)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
    }
}

