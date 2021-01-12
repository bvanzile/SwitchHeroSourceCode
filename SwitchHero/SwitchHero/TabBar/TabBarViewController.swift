//
//  TabBarViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 8/20/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit

enum ActiveTab {
    case first, second, third
}

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    // track the active tab number
    var activeTab: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.delegate = self
    }

    // called when a tab icon is touched
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //print("Selected \(item.title!)")
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected tab \(tabBarController.selectedIndex)")
        
        // track which tab was pressed
        let selected = tabBarController.selectedIndex
        
        switch selected {
        case 0:
            // first tab was tapped
            if activeTab == selected {
                // the Games tab was tapped when it is already visible, do something
                if let gamesvc = viewController.children[0] as? GamesTableViewController {
                    gamesvc.scrollToTop()
                }
            }
            activeTab = selected
            
        case 1:
            // second tab was tapped
            activeTab = selected
            
        case 2:
            // third was tapped
            activeTab = selected
            
        default:
            print("Should never reach here as there are always 3 possible tabs")
        }
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
