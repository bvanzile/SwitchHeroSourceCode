//
//  AboutTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 12/18/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class AboutTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    // didSelectRowAt hook
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get the selected cell
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // create the actions for each static cell
        if indexPath.section == 0 && indexPath.row == 0 {
            // Github link
            if !openInSafari(Config.AboutLinks.myGithubUrl) {
                cell.isUserInteractionEnabled = false
            }
        }
        else if indexPath.section == 0 && indexPath.row == 1 {
            // ig link
            if !openInSafari(Config.AboutLinks.myIgUrl) {
                cell.isUserInteractionEnabled = false
            }
        }
        else if indexPath.section == 1 && indexPath.row == 0 {
            // email link
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([Config.AboutLinks.contactEmail])

                present(mail, animated: true)
            }
        }
        else if indexPath.section == 2 && indexPath.row == 0 {
            // alamofire
            if !openInSafari(Config.AboutLinks.alamofire) {
                cell.isUserInteractionEnabled = false
            }
        }
        else if indexPath.section == 2 && indexPath.row == 1 {
            // sheeeeet
            if !openInSafari(Config.AboutLinks.sheet) {
                cell.isUserInteractionEnabled = false
            }
        }
        else if indexPath.section == 2 && indexPath.row == 2 {
            // nintendo-switch-eshop
            if !openInSafari(Config.AboutLinks.nintendoSwitchEshop) {
                cell.isUserInteractionEnabled = false
            }
        }
        else if indexPath.section == 2 && indexPath.row == 3 {
            // kingfisher
            if !openInSafari(Config.AboutLinks.kingfisher) {
                cell.isUserInteractionEnabled = false
            }
        }

        // deselect whatever cell was selected since they all should be acting as buttons
        cell.setSelected(false, animated: true)
    }
    
    // function for opening site in safari
    func openInSafari(_ stringUrl: String) -> Bool {
        // create the url
        if let url = URL(string: stringUrl) {
            if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                // display safari view with url
                let config = SFSafariViewController.Configuration()
                let vc = SFSafariViewController(url: url, configuration: config)
                
                self.present(vc, animated: true)
            }
            else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        else {
            print("Error generating url somehow")
            return false
        }
        
        return true
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
