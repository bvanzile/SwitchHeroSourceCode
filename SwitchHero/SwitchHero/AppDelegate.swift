//
//  AppDelegate.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/21/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import BackgroundTasks
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("application(1)")
        
        UNUserNotificationCenter.current().delegate = self
        
        // setup background tasks outlined in info.plist
        //self.registerBackgroundTasks()
        
        // Override point for customization after application launch.
        return true
    }
    
    // MARK: Register Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bvz.gamesRefresh", using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }
    
    // handle code for refreshing game data in the app background
    private func handleAppRefreshTask(task: BGAppRefreshTask) {
        // cancel ongoing operations when expiration time is reached
        task.expirationHandler = {
            // send a notification for testing
            let failed = LocalNotificationManager()
            failed.addNotification(title: "Background session expired", interval: 5)
            failed.schedule()
            
            print("Games refresh background task expired: failed to complete")
            // TODO: implement session cancel call here (possibly with alamofire?)
            
            // background refresh expired before task compelted
            task.setTaskCompleted(success: false)
        }
        
        // testing string to add to notification when game array has to be re-populated
        var repopulateString: String?
        
        // schedule another background update to chain these calls every X hours
        self.scheduleBackgroundGamesRefresh()
        
        // check if games is empty, sometimes it can be unallocated when in the background
        if GameManager.instance.isEmpty() {
            // attempt to re-populate games list from local json before attempting an update
            if !GameManager.instance.readGamesFile() {
                // failed to repopulate the games array from json so break free and wait until app is re-opened
                // send a notification for testing
                let failed = LocalNotificationManager()
                failed.addNotification(title: "Game array was empty and failed to update from json", interval: 5)
                failed.schedule()
                
                task.setTaskCompleted(success: false)
                return
            }
            
            // set test string
            repopulateString = "Game array was re-populated from json. "
        }
        
        // do the update
        GameManager.instance.retrieveGameUpdates() { (success, error, newGames) in
            if success {
                // save to file and show the table
                if !GameManager.instance.saveGamesJSONFile() {
                    print("Save failed after data was updated from API")
                }

                // create a notification for this update
                let notification = LocalNotificationManager()
                let title = (repopulateString ?? "") + "New updates: \(newGames ?? 0), Total games: \(GameManager.instance.count())"
                notification.addNotification(title: title, interval: 2)
                notification.schedule()
                
                task.setTaskCompleted(success: true)
            }
            else {
                print("API update failed with \(String(describing: error))")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // handle the scheduling for game refresh background activity
    func scheduleBackgroundGamesRefresh() {
        // retrieve the task and set to execute at least 10 seconds after app moves to background
        let gamesRefreshTask = BGAppRefreshTaskRequest(identifier: "com.bvz.gamesRefresh")
        gamesRefreshTask.earliestBeginDate = Date(timeIntervalSinceNow: (0.25 * 60 * 60))  // hours * min/hour * sec/min
        
        // schedule task
        do {
            try BGTaskScheduler.shared.submit(gamesRefreshTask)
        }
        catch {
            print("Unable to submit task \"com.bvz.gamesRefresh\": \(error.localizedDescription)")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("application(2) called")
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("application(3) called")
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

