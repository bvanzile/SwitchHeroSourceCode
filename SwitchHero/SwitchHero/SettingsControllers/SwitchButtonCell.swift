//
//  SwitchButtonCell.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 8/26/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit

// simple class for a table view cell that contains a switch button
class LocalNotificationsCell: UITableViewCell {

    let switchButton = UISwitch()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //self.accessoryView = self.switchButton
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
