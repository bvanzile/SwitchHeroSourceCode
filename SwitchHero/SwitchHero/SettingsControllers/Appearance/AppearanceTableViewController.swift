//
//  AppearanceTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 8/28/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import Sheeeeeeeeet

// table view controller for the Appearance section of the Settings menu
class AppearanceTableViewController: UITableViewController {
    // outlet and switch button for the "Use System Light/Dark Mode" cell
    @IBOutlet weak var useSystemModeCell: UITableViewCell!
    private var useSystemModeSwitch: UISwitch = UISwitch()
    private var defaultSeparatorInset: UIEdgeInsets = UIEdgeInsets()
    
    // outlet for the "Appearance" theme cell
    @IBOutlet weak var appearanceModeCell: UITableViewCell!
    
    // outlet and switch button for the "Favorited Deals Badge Count" cell
    @IBOutlet weak var favoritesBadgeCell: UITableViewCell!
    private var favoritesBadgeSwitch: UISwitch = UISwitch()
    
    // outlet and switch button for the "Highlight Deals Background" cell
    @IBOutlet weak var highlightDealsCell: UITableViewCell!
    private var highlightDealsSwitch: UISwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Loading the Appearance settings menu")
        self.title = "Appearance"
        
        // setup the use system default button
        var systemModeEnabled: Bool = false
        
        if let useSystemMode = UserDefaults.standard.object(forKey: Config.Settings.useSystemMode) as? Bool {
            // capture the value for use when settings up appearance mode cell
            systemModeEnabled = useSystemMode
            
            // update the switch based on the user's found setting
            useSystemModeSwitch.isOn = useSystemMode
        }
        else {
            // this setting was never set, so update with the default value
            useSystemModeSwitch.isOn = Config.Settings.DefaultValue.useSystemMode
            systemModeEnabled = Config.Settings.DefaultValue.useSystemMode
            UserDefaults.standard.set(Config.Settings.DefaultValue.useSystemMode, forKey: Config.Settings.useSystemMode)
        }
        
        useSystemModeSwitch.addTarget(self, action: #selector(useSystemModeSwitchChanged), for: .valueChanged)
        useSystemModeCell.accessoryView = useSystemModeSwitch
        
        // grab a copy of the automatic separator inset
        self.defaultSeparatorInset = useSystemModeCell.separatorInset
        
        // setup the Appearance button, which is hidden when above button is on
        if let appearance = UserDefaults.standard.object(forKey: Config.Settings.appearanceMode) as? String {
            // pass on the user saved setting to the right detail text label
            if appearance == Config.Settings.AppearanceModes.darkMode {
                appearanceModeCell.detailTextLabel?.text = appearance
            }
            else if appearance == Config.Settings.AppearanceModes.lightMode {
                appearanceModeCell.detailTextLabel?.text = appearance
            }
            else {
                // should never hit this, but hide text if it does
                appearanceModeCell.detailTextLabel?.text = ""
            }
        }
        else {
            // user setting was never set, so make it the default value
            appearanceModeCell.detailTextLabel?.text = Config.Settings.DefaultValue.appearanceMode
            UserDefaults.standard.set(Config.Settings.DefaultValue.appearanceMode, forKey: Config.Settings.appearanceMode)
        }
        
        // hide the cell if appearance is using system theme
        if systemModeEnabled {
            appearanceModeCell.isHidden = true
            useSystemModeCell.separatorInset = .hiddenSeparator
        }
        
        // setup the favorites badge count switch
        if let favoritesBadge = UserDefaults.standard.object(forKey: Config.Settings.favoritesBadgeCount) as? Bool {
            // flip the switch if user setting is true
            if favoritesBadge {
                favoritesBadgeSwitch.isOn = true
            }
        }
        else {
            // user setting was never set so setup with default value
            favoritesBadgeSwitch.isOn = Config.Settings.DefaultValue.favoritesBadgeCount
            UserDefaults.standard.set(Config.Settings.DefaultValue.favoritesBadgeCount, forKey: Config.Settings.favoritesBadgeCount)
        }
        
        favoritesBadgeSwitch.addTarget(self, action: #selector(favoritedDealsBadgeCountChanged), for: .valueChanged)
        favoritesBadgeCell.accessoryView = favoritesBadgeSwitch
        
        // setup the highlight deals background switch
        if let highlightDeals = UserDefaults.standard.object(forKey: Config.Settings.highlightDeals) as? Bool {
            // flip the switch if user setting is true
            if highlightDeals {
                highlightDealsSwitch.isOn = true
            }
        }
        else {
            // user setting was never set so setup with default value
            highlightDealsSwitch.isOn = Config.Settings.DefaultValue.highlightDeals
            UserDefaults.standard.set(Config.Settings.DefaultValue.highlightDeals, forKey: Config.Settings.highlightDeals)
        }
        
        highlightDealsSwitch.addTarget(self, action: #selector(highlightDealsChanged), for: .valueChanged)
        highlightDealsCell.accessoryView = highlightDealsSwitch
    }
    
    @objc private func useSystemModeSwitchChanged(_ sender: UISwitch) {
        print("Use System Mode value changed to \(sender.isOn)")
        
        // update value in settings
        UserDefaults.standard.set(sender.isOn, forKey: Config.Settings.useSystemMode)
        
        // hide or unhide the appearance cell, if required
        if sender.isOn {
            self.appearanceModeCell.isHidden = true
            self.useSystemModeCell.separatorInset = .hiddenSeparator
            
            // set interface style to system value
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        else {
            self.appearanceModeCell.isHidden = false
            self.useSystemModeCell.separatorInset = self.defaultSeparatorInset
            
            // set interface style to whatever is set in appearance setting or the default
            var newStyle: UIUserInterfaceStyle
            if let userSetting = UserDefaults.standard.object(forKey: Config.Settings.appearanceMode) as? String {
                if userSetting == Config.Settings.AppearanceModes.lightMode {
                    newStyle = .light
                }
                else {
                    // should only be light or dark, and if the returned string misses somehow, just give dark
                    newStyle = .dark
                }
            }
            else {
                // user setting was never set somehow
                if Config.Settings.DefaultValue.appearanceMode == Config.Settings.AppearanceModes.lightMode {
                    newStyle = .light
                }
                else {
                    newStyle = .dark
                }
            }
            
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = newStyle
            }
        }
        
        self.tableView.reloadData()
    }
    
    @objc private func favoritedDealsBadgeCountChanged(_ sender: UISwitch) {
        print("Favorited deals badge count changed to \(sender.isOn)")
        
        // change the value within user settings
        UserDefaults.standard.set(sender.isOn, forKey: Config.Settings.favoritesBadgeCount)
        
        // trigger an update to the badge icon
        GameManager.instance.updateTabBar()
    }
    
    @objc private func highlightDealsChanged(_ sender: UISwitch) {
        print("Highlight deal backgrounds changed to \(sender.isOn)")
        
        // change the value within user settings
        UserDefaults.standard.set(sender.isOn, forKey: Config.Settings.highlightDeals)
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    // called when cell is tapped, but only needed for the one Appearance cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // take action for the appearance cell only
        if indexPath.section == 0 && indexPath.row == 1 {
            // get the appearance cell... or else..
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            
            // get the currently active appearance from UserDefaults
            var selected = ""
            if let activeAppearance = UserDefaults.standard.object(forKey: Config.Settings.appearanceMode) as? String {
                selected = activeAppearance
            }
            
            // create and display the action sheet for selecting
            let darkModeMenuItem: SingleSelectItem = SingleSelectItem(title: Config.Settings.AppearanceModes.darkMode, subtitle: nil, isSelected: (selected == Config.Settings.AppearanceModes.darkMode) ? true : false, group: "Appearance", value: Config.Settings.AppearanceModes.darkMode, image: nil, tapBehavior: .dismiss)
            let lightModeMenuItem: SingleSelectItem = SingleSelectItem(title: Config.Settings.AppearanceModes.lightMode, subtitle: nil, isSelected: (selected == Config.Settings.AppearanceModes.lightMode) ? true : false, group: "Appearance", value: Config.Settings.AppearanceModes.lightMode, image: nil, tapBehavior: .dismiss)
            
            // default cancel button at the bottom of the menu
            let cancel = CancelButton(title: "Cancel")
            
            // build the menu object
            let items = [darkModeMenuItem, lightModeMenuItem, cancel]
            let menu = Menu(items: items)
            
            // create the action sheet
            let actionSheet = ActionSheet(menu: menu, configuration: .backgroundDismissable) { sheet, item in
                // execute the action based on which item was pressed
                if let selected = item.value as? String {
                    switch selected {
                    case Config.Settings.AppearanceModes.darkMode:
                        print("Selected \(selected)")
                        cell.detailTextLabel?.text = selected
                        UserDefaults.standard.set(selected, forKey: Config.Settings.appearanceMode)
                        
                        UIApplication.shared.windows.forEach { window in
                            window.overrideUserInterfaceStyle = .dark
                        }
                        
                    case Config.Settings.AppearanceModes.lightMode:
                        print("Selected \(selected)")
                        cell.detailTextLabel?.text = selected
                        UserDefaults.standard.set(selected, forKey: Config.Settings.appearanceMode)
                        
                        UIApplication.shared.windows.forEach { window in
                            window.overrideUserInterfaceStyle = .light
                        }
                        
                    default:
                        print("Default option hit somehow")
                    }
                }
                else {
                    print("Non-action selected: \(item.value ?? "nil")")
                }
            }
            
            // display the action sheet
            actionSheet.present(in: self, from: self.view)
            
            // reset the cell
            cell.isSelected = false
        }
    }
    
    // dynamically change the Appearance cell's height when it is hidden
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // determine if this is the Appearance cell
        if indexPath.section == 0 && indexPath.row == 1 {
            if self.appearanceModeCell.isHidden {
                return 0.0
            }
        }

        return 44.0
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
