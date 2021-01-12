//
//  GameDetailsTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 5/18/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit

class GameDetailsTableViewController: UITableViewController {
    
    @IBOutlet weak var releaseDateCell: UITableViewCell!
    @IBOutlet weak var releaseDateLabel: UILabel!
    
    @IBOutlet weak var playersCell: UITableViewCell!
    @IBOutlet weak var playersLabel: UILabel!
    
    @IBOutlet weak var ganresCell: UITableViewCell!
    @IBOutlet weak var genresLabel: UILabel!
    
    @IBOutlet weak var lowestPriceCell: UITableViewCell!
    @IBOutlet weak var lowestPriceLabel: UILabel!
    
    @IBOutlet weak var fileSizeCell: UITableViewCell!
    @IBOutlet weak var fileSizeLabel: UILabel!
    
    @IBOutlet weak var developerCell: UITableViewCell!
    @IBOutlet weak var developerLabel: UILabel!
    
    @IBOutlet weak var publisherCell: UITableViewCell!
    @IBOutlet weak var publisherLabel: UILabel!
    
    @IBOutlet weak var esrbCell: UITableViewCell!
    @IBOutlet weak var esrbDescriptorLabel: UILabel!
    
    @IBOutlet weak var supportedLanguagesCell: UITableViewCell!
    @IBOutlet weak var supportedLanguagesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Config.Settings.getInterfaceStyle() == .light {
            self.tableView.separatorColor = .darkGray
        }
    }
    
    // callback for populating the table
    func populateDetailsTable(_ game: Game) {
        // check for bad data
        if game.fullDetails == nil {
            print("Failed to pass game details to the table")
            return
        }
        
        // release date label
        if let releaseDate = game.releaseDate {
            let listingDateFormat = DateFormatter()
            listingDateFormat.dateFormat = Config.GameDefaults.dateListingFormat
            
            if releaseDate < Date() {
                self.releaseDateLabel.text = "Released: \(listingDateFormat.string(from: releaseDate))"
            }
            else {
                self.releaseDateLabel.text = "Releases: \(listingDateFormat.string(from: releaseDate))"
            }
        }
        else {
            self.releaseDateLabel.text = "Releases: \(game.availabilityString)"
        }
        
        // players label
        self.playersLabel.text = "Players: " + game.fullDetails!.numOfPlayers.capitalizingFirstLetter()

        // genres label
        if game.fullDetails!.genres.count > 0 {
            self.genresLabel.text = Config.concatenateStringArray(game.fullDetails!.genres, prefix: "Genres: ", default: "No genres")
        }
        else {
            self.ganresCell.isHidden = true
        }
        
        // lowest price label
        if game.fullDetails!.lowestPrice > 0 {
            self.lowestPriceLabel.text = "Lowest Price: $\(game.fullDetails!.lowestPrice)"
        }
        else {
            self.lowestPriceCell.isHidden = true
        }

        // file size label
        if game.fullDetails!.fileSize != "" {
            self.fileSizeLabel.text = "File size: " + game.fullDetails!.fileSize
        }
        else {
            self.fileSizeCell.isHidden = true
        }

        // developer label
        if game.fullDetails!.developers.count > 0 {
            self.developerLabel.text = Config.concatenateStringArray(game.fullDetails!.developers, prefix: "Developer: ", default: "Developer unknown")
        }
        else {
            self.developerCell.isHidden = true
        }

        // publisher label
        if game.fullDetails!.publishers.count > 0 {
            self.publisherLabel.text = Config.concatenateStringArray(game.fullDetails!.publishers, prefix: "Publisher: ", default: "Publisher unknown")
        }
        else {
            self.publisherCell.isHidden = true
        }

        // esrb label
        if game.fullDetails!.esrbDescriptors.count > 0 {
            self.esrbDescriptorLabel.text = Config.concatenateStringArray(game.fullDetails!.esrbDescriptors, prefix: (game.fullDetails!.esrbRating + ": "))
        }
        else {
            self.esrbDescriptorLabel.text = game.fullDetails!.esrbRating
        }

        // supported languages
        if game.fullDetails!.supportedLanguages != "" {
            self.supportedLanguagesLabel.text = "Supported languages: " + game.fullDetails!.supportedLanguages
        }
        else {
            self.supportedLanguagesCell.isHidden = true

            // hide the row above the supported language's separator so the bottom is blank
            self.esrbCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tableViewCell = super.tableView(tableView, cellForRowAt: indexPath)

        if tableViewCell.isHidden == true {
            return 0
        }
        else{
             return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // sets the preferred content size to the actual size of the table with all content in it so parent view can resize table to what is necessary
        if preferredContentSize.height != tableView.contentSize.height {
            preferredContentSize.height = tableView.contentSize.height
        }
    }
}
