//
//  FavoritesTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/29/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import Sheeeeeeeeet
import SafariServices

class FavoritesTableViewController: UITableViewController {
    // view for when no games are on the wishlist (setup in storyboard)
    @IBOutlet var emptyLabel: UIView!
    
    // activity spinner for when games are loading
    var activityIndicatorView: UIActivityIndicatorView!
    
    // for swiping down to refresh data
    private let refresh = UIRefreshControl()
    
    // custom options button for the top right nav bar
    var optionsNavBarButton: UIBarButtonItem?
    
    // option pulled from settings
    private var highlightDeals: Bool?
    
    override func loadView() {
        super.loadView()
        print("FavoritesTableViewController->loadView()")
    
        // spinner created and setup in the background view for use if necessary
        activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        tableView.backgroundView = activityIndicatorView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the title
        self.title = Config.TabTitle.second

        // set a blank view under table so extra separators dont show
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        // configure refresh control
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(refreshGamesData(_:)), for: .valueChanged)

        // set up the options navigation bar button
        let optionsButton = UIButton(type: .custom)
        optionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        optionsButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        optionsButton.addTarget(self, action: #selector(optionsButtonTouched(_:)), for: .touchUpInside)

        // create the custom view/layout/callback
        self.optionsNavBarButton = UIBarButtonItem(customView: optionsButton)
        var resizedFrame = self.optionsNavBarButton!.customView!.frame
        resizedFrame.size.width = 30
        self.optionsNavBarButton!.customView!.frame = resizedFrame
        
        // setup the top right button
        self.navigationItem.rightBarButtonItem = self.optionsNavBarButton//self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // update whether deal backgrounds need to be highlighted
        if let highlight = UserDefaults.standard.object(forKey: Config.Settings.highlightDeals) as? Bool {
            // get the user setting
            self.highlightDeals = highlight
            print("View appearing, highlight is \(highlight)")
        }
        else {
            // update user setting with default if non was previously set
            print("View appearing, defaulting highlight")
            self.highlightDeals = Config.Settings.DefaultValue.highlightDeals
            UserDefaults.standard.set(Config.Settings.DefaultValue.highlightDeals, forKey: Config.Settings.highlightDeals)
        }
        
        // make sure the right separator color is selected
        if Config.Settings.getInterfaceStyle() == .light {
            self.tableView.separatorColor = .darkGray
        }
        else {
            self.tableView.separatorColor = .white
        }

        // if games aren't loaded, start animating loading spinner and listen for the favorites list to finish loading
        if GameManager.instance.isEmpty() {
            // animate
            activityIndicatorView.startAnimating()
            tableView.separatorStyle = .none

            NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "FavoritesLoaded"), object: nil)
        }
        else {
            self.tableView.reloadData()
            print("Data reloaded when entering view")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove observer, if set
        NotificationCenter.default.removeObserver(self)
    }
    
    // objc func for reloading the table
    @objc func reload() {
        DispatchQueue.main.async {
            self.tableView.separatorStyle = .singleLine
            self.tableView.reloadData()
        }
    }
    
    // options (...) navigation bar button was touched
    @objc func optionsButtonTouched(_ sender: Any) {
        // edit button
        let item1 = MenuItem(title: "Edit", subtitle: nil, value: Config.FavoritesOptionMenu.edit, image: UIImage(systemName: "folder"), isEnabled: true, tapBehavior: .dismiss)
        
        // add buttons for the eshop and share options
        let item2 = MenuItem(title: "Open Nintendo.com Wishlist", subtitle: nil, value: Config.FavoritesOptionMenu.openWishlist, image: UIImage(named: "switch.icon"), isEnabled: true, tapBehavior: .dismiss)
        
        // default cancel button at the bottom of the menu
        let cancel = CancelButton(title: "Cancel")
        
        // build the menu object
        let items = [item1, item2, cancel]
        let menu = Menu(items: items)
        
        // create the action sheet
        let actionSheet = ActionSheet(menu: menu, configuration: .backgroundDismissable) { sheet, item in
            // execute the action based on which item was pressed
            if let selected = item.value as? Config.FavoritesOptionMenu {
                switch selected {
                case .edit:
                    // enable editing and change the button
                    self.setEditing(true, animated: true)
                    
                case .openWishlist:
                    // open the nintendo.com wishlist in Safari viewer
                    if let url = URL(string: Config.nintendoWishListUrl) {
                        let config = SFSafariViewController.Configuration()
                        let vc = SFSafariViewController(url: url, configuration: config)
                        self.present(vc, animated: true)
                    }
                    else {
                        print("Error generating url somehow")
                    }
                }
            }
            else {
                print("Non-action selected: \(item.value ?? "nil")")
            }
        }
        
        // display the action sheet
        actionSheet.present(in: self, from: self.view)
    }
    
    // override setEditing so we can swap the nav bar button when starting to edit and finishing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // if starting to edit, change nav bar button to edit button and change back when it ends
        if editing {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        }
        else {
            self.navigationItem.rightBarButtonItem = self.optionsNavBarButton
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = GameManager.instance.favoritesCount()
        
        if rows > 0 {
            self.tableView.backgroundView = nil
        }
        else if GameManager.instance.isEmpty() {
            self.tableView.backgroundView = activityIndicatorView
        }
        else {
            self.tableView.backgroundView = emptyLabel
        }
        
        return rows
    }
    
    // draws the table cell when in view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("GamesTableViewController->tableView(cellForRowAt = \(indexPath.row))")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoritesCell", for: indexPath) as! FavoritesTableViewCell

        guard let game = GameManager.instance.getFavoritedGame(atIndex: indexPath.row) else { return cell }
        
        cell.title?.text = game.listing.title
        
        var releaseDateString: String = ""
        if let releaseDate = game.releaseDate {
            let listingDateFormat = DateFormatter()
            listingDateFormat.dateFormat = Config.GameDefaults.dateListingFormat
            
            releaseDateString = listingDateFormat.string(from: releaseDate)
        }
        else {
            releaseDateString = game.availabilityString
        }
        
        // setup new attributed string by copying the value
        let attributedShortDescriptionString = NSMutableAttributedString(string: "")
        
        // build the price portion of the description
        if game.listing.hasPrice {
            attributedShortDescriptionString.append(game.getAttributedPriceString(fontSize: 14))
            attributedShortDescriptionString.append(NSAttributedString(string: "  "))
        }
        
        // get color of calendar based on interface style
        let calendarColor: UIColor
        if Config.Settings.getInterfaceStyle() == .dark {
            calendarColor = .white
        }
        else {
            calendarColor = .black
        }
        
        if let calendarImage = UIImage(systemName: "calendar")?.colorImage(with: calendarColor) {
            let calendarImageAttachment = NSTextAttachment()
            
            if let capHeight = cell.shortDescription?.font.capHeight, let bounds = cell.shortDescription?.bounds {
                calendarImageAttachment.bounds = CGRect(x: 0, y: (capHeight - (bounds.height * 0.75)).rounded() / 2, width: (bounds.height * 0.75), height: (bounds.height * 0.75))
            }
            
            calendarImageAttachment.image = calendarImage
            
            let calendarImageString = NSAttributedString(attachment: calendarImageAttachment)
            attributedShortDescriptionString.append(calendarImageString)
            attributedShortDescriptionString.append(NSMutableAttributedString(string: " " + releaseDateString))
        }
        
        cell.shortDescription?.attributedText = attributedShortDescriptionString
        
        // check if the background needs to be changed
        if self.highlightDeals != nil && self.highlightDeals! {
            // handle background color change if the game is on sale
            if game.listing.onSale {
                // change cell background color based on current app interface style (dark or light)
                cell.backgroundColor = Config.Settings.getInterfaceStyle() == .light ? Config.GameCell.lightSale : Config.GameCell.darkSale
            }
            else {
                // change cell background color based on current app interface style (dark or light)
                cell.backgroundColor = Config.Settings.getInterfaceStyle() == .light ? Config.GameCell.defaultLight : Config.GameCell.defaultDark
            }
        }
        else {
            cell.backgroundColor = Config.Settings.getInterfaceStyle() == .light ? Config.GameCell.defaultLight : Config.GameCell.defaultDark
        }
    
        // set the box art from Nintendo url, memory, or cache
        if let url = game.getBoxArtUrl() {
            // setup the presentation while it is loading
            cell.boxArt.kf.indicatorType = .activity
            
            // make network call or retrieve from disk or network cache
            cell.boxArt.kf.setImage(with: url, completionHandler: { result in
                // `result` is either a `.success(RetrieveImageResult)` or a `.failure(KingfisherError)`
                switch result {
                case .success(_):   // case .success(let value):
                    // From where the image was retrieved:
                    // - .none - Just downloaded.
                    // - .memory - Got from memory cache.
                    // - .disk - Got from disk cache.
                    //print("\(game.details.title) box art retrieved from \(value.cacheType)")
                    break
                    
                case .failure(let error):
                    // print error and set to default value
                    cell.boxArt.image = UIImage(systemName: "photo")
                    print(error)
                }
            })
        }
        else {
            print("Failed to create box art url from \(game.listing.boxart)")
        }

        return cell
    }
    
    // override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // delete the row from the data source
            guard let game = GameManager.instance.getFavoritedGame(atIndex: indexPath.row) else { return }
            
            // protect against crashes
            tableView.beginUpdates()
            
            if game.favoriteActionTaken() == false {
                // if result of favorited action is now false, remove from the table
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            tableView.endUpdates()
        }
    }
    
    // for changing order of favorited games
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        GameManager.instance.moveFavoritedGames(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
    }
    
    // for helping with dynamically sized table cell heights
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // function call for executing a table refresh by pulling down at the top of the table
    @objc private func refreshGamesData(_ sender: Any) {
        // if empty on refresh for some reason, try to read json first
        if GameManager.instance.isEmpty() {
            print("Game manager empty, getting data")
            
            // alert refresh view and background view that process has started
            self.refresh.beginRefreshing()

            DispatchQueue.global(qos: .background).async {
                // attempt to read from the persistent json
                if GameManager.instance.readGamesFile() {
                    // populate favorites after games json is loaded
                    GameManager.instance.updateFavorites()
                    
                    DispatchQueue.main.async {
                        // reload the table
                        self.refresh.endRefreshing()
                        self.tableView.reloadData()
                    }
                }
                else {
                    // if json cant be read from the file, do a complete update from the api and save the new json
                    GameManager.instance.retrieveGameUpdates() { (success, error, new) in
                        // save the updates to the persistent json file
                        if success {
                            // save new game json to file
                            if !GameManager.instance.saveGamesJSONFile() {
                                print("Save failed")
                            }
                            
                            DispatchQueue.main.async {
                                // reload the table and show rows
                                self.refresh.endRefreshing()
                                self.tableView.reloadData()
                            }
                        }
                        else {
                            print("API update failed with \(String(describing: error))")
                            
                            DispatchQueue.main.async {
                                self.refresh.endRefreshing()
                                self.activityIndicatorView.stopAnimating()
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        else {
            // perform api update and save json
            GameManager.instance.retrieveGameUpdates() { (success, error, new) in
                // save the updates to the persistent json file
                if success {
                    // save new game json to file
                    if !GameManager.instance.saveGamesJSONFile() {
                        print("Save failed")
                    }
                    
                    DispatchQueue.main.async {
                        // reload the table and show rows
                        self.refresh.endRefreshing()
                        self.tableView.reloadData()
                    }
                }
                else {
                    print("API update failed with \(String(describing: error))")
                    
                    DispatchQueue.main.async {
                        self.refresh.endRefreshing()
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    // preparation before segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass along the game object for the cell that was selected
        if segue.identifier == "viewGameDetails" {
            if let destinationVC = segue.destination as? GameDetailsViewController {
                if let index = self.tableView.indexPathForSelectedRow?.row {
                    destinationVC.game = GameManager.instance.getFavoritedGame(atIndex: index)
                }
            }
        }
    }
}
