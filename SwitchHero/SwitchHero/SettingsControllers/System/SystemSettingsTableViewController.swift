//
//  SystemSettingsTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 5/25/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import Kingfisher

class SystemSettingsTableViewController: UITableViewController {
    // custom row disabling functionality
    private var disabledRows: [IndexPath] = []

    // KingFisher cache object
    private let cache = ImageCache.default
    
    // cache size variables
    @IBOutlet weak var cacheSizeLabel: UILabel!
    private var cacheSize: String = ""
    
    // cell for refreshing games
    @IBOutlet weak var refreshCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateCacheSize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCacheSize()
    }
    
    private func updateCacheSize() {
        cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                self.cacheSize = String(format: "%.0f", Double(size) / 1024 / 1024)
                self.cacheSizeLabel.text = "\(self.cacheSize) MB"
                self.cacheSizeLabel.isHidden = false
                
            case .failure(let error):
                print(error)
                self.cacheSizeLabel.isHidden = true
            }
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Clear Cache option
        if indexPath.section == 0 && indexPath.row == 0 {
            // deselect immediately and show alert
            tableView.deselectRow(at: indexPath, animated: true)
            
            let alert = UIAlertController(title: "Clear cache?", message: "The current cache size on disk is \(cacheSize) MB", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in }))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(_: UIAlertAction!) in
                //self.cache.clearMemoryCache()
                self.cache.clearDiskCache {
                    print("Cache cleared")
                    self.updateCacheSize()
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        // Refresh Games option
        else if indexPath.section == 1 && indexPath.row == 0 {
            print("Data Refresh selected")
            
            // create an activity indicator for the cell to show while data is being retrieved
            let activityIndicator = UIActivityIndicatorView()
            
            // add activity indicator to view and start animating
            refreshCell.accessoryView = activityIndicator
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            activityIndicator.startAnimating()
            
            // dont allow cell selection for the duration of the update
            self.disableRow(indexPath)
            
            // start refresh activities
            DispatchQueue.global(qos: .background).async {
                // if json cant be read from the file, do a complete update from the api and save the new json
                GameManager.instance.retrieveGameUpdates(fullRefresh: true) { (success, error, count) in
                    // re-enable the cell for selection
                    self.enableRow(indexPath)
                    
                    // check results
                    if success && count != nil {
                        // save the updates to the persistent json file
                        if !GameManager.instance.saveGamesJSONFile() {
                            print("Save failed")
                        }

                        DispatchQueue.main.async {
                            // deselect immediately and show alert
                            tableView.deselectRow(at: indexPath, animated: true)
                            
                            // display an alert with the results
                            let alert = UIAlertController(title: "Game data successfully refreshed", message: String(count!) + " games retrieved.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            self.present(alert, animated: true)
                            
                            // stop and remove the activity indicator
                            activityIndicator.stopAnimating()
                            activityIndicator.removeFromSuperview()
                        }
                    }
                    else {
                        print("API update failed with \(String(describing: error))")

                        DispatchQueue.main.async {
                            // deselect immediately and show alert
                            tableView.deselectRow(at: indexPath, animated: true)
                            
                            // display an alert with the results
                            let alert = UIAlertController(title: "Game data refresh failed", message: "There was an issue retrieving game updates. Please try again.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                            self.present(alert, animated: true)
                            
                            // stop and remove the activity indicator
                            activityIndicator.stopAnimating()
                            activityIndicator.removeFromSuperview()
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.disabledRows.contains(indexPath) {
            print("Blocked row selection")
            return nil
        }
        
        return indexPath
    }
    
    // disable passed in row
    private func disableRow(_ indexPath: IndexPath) {
        self.disabledRows.append(indexPath)
    }
    
    // enable passed in row
    private func enableRow(_ indexPath: IndexPath) {
        self.disabledRows.removeAll(where: { $0 == indexPath })
    }
}
