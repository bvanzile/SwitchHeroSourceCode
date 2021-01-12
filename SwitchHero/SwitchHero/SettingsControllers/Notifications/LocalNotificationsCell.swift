//
//  LocalNotificationsCell.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 8/26/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import UserNotifications

// simple class for a table view cell that contains a switch button
class LocalNotificationsCell: UITableViewCell {

    // switch button attached to the favorites sales row
    let switchButton = UISwitch()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        // default to off then check if it should be on
        self.switchButton.isOn = false
        
        // assign the value for the local notifications setting from UserDefaults
        if let setting = UserDefaults.standard.object(forKey: Config.Settings.localNotifications) as? Bool {
            // turn the switch button on if it is saved
            if setting == true {
                self.switchButton.isOn = true
                print("Setting saved as true")
            }
            else if setting == false {
                print("Setting saved as false")
            }
            else {
                print("Not true or false")
            }
        }
        else {
            // setting value was never set, so set to default
            UserDefaults.standard.set(Config.Settings.DefaultValue.localNotifications, forKey: Config.Settings.localNotifications)
        }
        
        // assign value changed function to switch button
        self.switchButton.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        
        // add the switch to the accessory view of this cell
        self.accessoryView = self.switchButton
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // called when the switch button is pressed
    @objc private func switchChanged(_ senderSwitch: UISwitch) {
        print("Local Notifications setting changed to \(senderSwitch.isOn ? "on" : "off")")
        
        // if the switch is turning on, request permissions if necessary
        if senderSwitch.isOn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { granted, error in
                if granted == true && error == nil {
                    // permission is granted and the setting can be changed to true
                    UserDefaults.standard.set(true, forKey: Config.Settings.localNotifications)
                }
                else {
                    // move the switch back to off
                    DispatchQueue.main.async {
                        // permission is denied, so offer an alert with the option of opening the settings menu
                        let alert = UIAlertController(title: "Notifications Permission Denied", message: "To turn on local notifications, Notifications permission needs to be allowed in the Settings app.", preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in }))
                        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: {(_: UIAlertAction!) in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }))
                        
                        UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController?.present(alert, animated: true, completion: nil)
                        senderSwitch.setOn(false, animated: true)
                    }
                }
            }
        }
        else {
            // update the setting when the new value is provided
            UserDefaults.standard.set(false, forKey: Config.Settings.localNotifications)
        }
    }

}
