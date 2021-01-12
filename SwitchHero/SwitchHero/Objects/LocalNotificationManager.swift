//
//  LocalNotificationManager.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 8/11/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation
import UserNotifications

struct Notification {
    var id: String
    var title: String
    var interval: TimeInterval
}

class LocalNotificationManager {
    var notifications = [Notification]()
    
    func addNotification(title: String, interval: TimeInterval) {
        notifications.append(Notification(id: UUID().uuidString, title: title, interval: interval))
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .alert]) { granted, error in
            if granted == true && error == nil {
                print("Permission granted")
            }
        }
    }
    
    func schedule() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestPermission()
            case .authorized, .provisional:
                self.scheduleNotifications()
            default:
                break
            }
        }
    }
    
    private func scheduleNotifications() {
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notification.interval, repeats: false)
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                guard error == nil else { return }
                print("Scheduling notification with id: \(notification.id)")
            }
        }
    }
}
