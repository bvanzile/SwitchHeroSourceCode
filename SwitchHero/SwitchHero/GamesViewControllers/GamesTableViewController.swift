//
//  GamesTableViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/24/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import Kingfisher
import Sheeeeeeeeet

class GamesTableViewController: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UITableViewDataSourcePrefetching {
    // spinner view for showing while data is loaded
    var activityIndicatorView: UIActivityIndicatorView!
    
    // search controller placed at the top of the table
    let searchController = UISearchController(searchResultsController: nil)
    
    // for swiping down to refresh data
    private let refresh = UIRefreshControl()
    
    // view for no data (usually network fail on first launch)
    @IBOutlet var noDataBgView: UIView!
    
    // user setting option for displaying deal cells with different background color
    var highlightDeals: Bool?
    
    override func loadView() {
        super.loadView()
        print("GamesTableViewController->loadView()")
    
        activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        tableView.backgroundView = activityIndicatorView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("GamesTableViewController->viewDidLoad()")
        
        self.title = Config.TabTitle.first
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        // set views above and below table so extra separators dont show
        self.tableView.tableHeaderView = UIView()
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        // configure refresh control
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(refreshGamesData(_:)), for: .valueChanged)
        
//        self.edgesForExtendedLayout = .top
//        self.tableView.contentInsetAdjustmentBehavior = .always
        
        // setup the search bar
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.delegate = self
        searchController.view.layoutIfNeeded()                      // avoid snapshotting a view error
        navigationItem.searchController = searchController
        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true
        
        //self.tableView.contentInsetAdjustmentBehavior = .never
        
        // prefectch setup
        tableView.prefetchDataSource = self
        
        // grab reference to favorites tab bar item
        GameManager.instance.retrieveFavoritesTabBarItem(tabBarController?.tabBar.items?[1])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("GamesTableViewController->viewWillAppear(animated = \(animated))")
        self.tableView.backgroundView = nil
    
        // update whether deal backgrounds need to be highlighted
        if let highlight = UserDefaults.standard.object(forKey: Config.Settings.highlightDeals) as? Bool {
            // get the user setting
            self.highlightDeals = highlight
        }
        else {
            // update user setting with default if non was previously set
            self.highlightDeals = Config.Settings.DefaultValue.highlightDeals
            UserDefaults.standard.set(Config.Settings.DefaultValue.highlightDeals, forKey: Config.Settings.highlightDeals)
        }
        
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // make sure the right separator color is selected
        if Config.Settings.getInterfaceStyle() == .light {
            self.tableView.separatorColor = .darkGray
        }
        else {
            self.tableView.separatorColor = .white
        }
        
        // check if no games are loaded
        if GameManager.instance.isEmpty() {
            print("Game manager empty, getting data")
            
            // prepare activity indicator to show while json loads
            activityIndicatorView.startAnimating()
            self.tableView.backgroundView = self.activityIndicatorView
            self.tableView.separatorStyle = .none

            // start loading activities
            DispatchQueue.global(qos: .background).async {
                // attempt to read from the persistent json
                if GameManager.instance.readGamesFile() && !GameManager.instance.isEmpty() {
                    DispatchQueue.main.async {
                        // reload the table and show rows
                        self.activityIndicatorView.stopAnimating()
                        self.tableView.separatorStyle = .singleLine
                        self.tableView.reloadData()
                        
                        self.refresh.sendActions(for: .valueChanged)
                    }
                }
                else {
                    // if json cant be read from the file, do a complete update from the api and save the new json
                    GameManager.instance.retrieveGameUpdates(fullRefresh: true) { (success, error, count) in
                        // save the updates to the persistent json file
                        if success {
                            if !GameManager.instance.saveGamesJSONFile() {
                                print("Save failed")
                            }
                            
                            DispatchQueue.main.async {
                                // reload the table and show rows
                                self.activityIndicatorView.stopAnimating()
                                self.tableView.separatorStyle = .singleLine
                                self.tableView.reloadData()
                            }
                        }
                        else {
                            print("API update failed with \(String(describing: error))")

                            if let customError = error as? Config.CustomError {
                                if customError == .activeUpdateOngoing {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                                else {
                                    DispatchQueue.main.async {
                                        self.activityIndicatorView.stopAnimating()
                                        self.tableView.backgroundView = self.noDataBgView
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    self.activityIndicatorView.stopAnimating()
                                    self.tableView.backgroundView = self.noDataBgView
                                    self.tableView.reloadData()
                                }
                            }
                            
                        }
                    }
                }
            }
        }
        else {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //print("numberOfSections")
        return (GameManager.instance.isEmpty()) ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("numberOfRows")
        return GameManager.instance.gamesTabRowCount() ?? 0
    }
    
    // draws the table cell when in view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("GamesTableViewController->tableView(cellForRowAt = \(indexPath.row))")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameListingCell", for: indexPath) as! GamesTableViewCell

        guard let game = GameManager.instance.getGameForRow(atIndex: indexPath.row) else { return cell }
        
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
        if Config.Settings.getInterfaceStyle() == .light {
            calendarColor = .black
        }
        else {
            calendarColor = .white
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
        
        if game.listing.featured {
            if let featuredImage = UIImage(named: "featuredStar") {
                let featuredImageAttachment = NSTextAttachment()
                
                if let capHeight = cell.shortDescription?.font.capHeight, let bounds = cell.shortDescription?.bounds {
                    featuredImageAttachment.bounds = CGRect(x: 0, y: (capHeight - bounds.height).rounded() / 2, width: bounds.height, height: bounds.height)
                }
                
                featuredImageAttachment.image = featuredImage
                
                let featuredImageString = NSAttributedString(attachment: featuredImageAttachment)
                attributedShortDescriptionString.append(NSAttributedString(string: "  "))
                attributedShortDescriptionString.append(featuredImageString)
                attributedShortDescriptionString.append(NSAttributedString(string: " Featured"))
            }
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
        
        if let url = game.getBoxArtUrl() {
            // setup the presentation while it is loading
            cell.boxArt.kf.indicatorType = .activity
            
            // make network call or retrieve from disk or network cache
            cell.boxArt.kf.setImage(with: url, completionHandler: { result in
                // `result` is either a `.success(RetrieveImageResult)` or a `.failure(KingfisherError)`
                switch result {
                case .success(let value):
                    print("\(game.listing.title) box art retrieved from \(value.cacheType)")
                    break
                    
                case .failure(let error):
                    // print error and set to default value
                    if !error.isTaskCancelled && !error.isNotCurrentTask {
                        cell.boxArt.image = UIImage(systemName: "photo")
                    }
                    else {
                        print("setImage failed with error \(error.errorCode): \(error.errorDescription ?? "nil msg")")
                    }
                }
            })
        }
        else {
            print("Failed to create box art url from \(game.listing.boxart)")
        }
        
        // show or hide the favorited triangle
        if game.favorited {
            cell.favoritedImage.isHidden = false
        }
        else {
            cell.favoritedImage.isHidden = true
        }

        return cell
    }
    
    // prefetching for box art image
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("    prefetching row of \(indexPaths)")
        
        var urls: [URL] = []
        
        // iterate through prefetch indexes
        for indexPath in indexPaths {
            // verifying cell section
            if indexPath.section == 0 {
                // get the game
                guard let game = GameManager.instance.getGameForRow(atIndex: indexPath.row) else { return }
                
                if let url = game.getBoxArtUrl() {
                    urls.append(url)
                }
            }
        }
        
        if urls.count > 0 {
            ImagePrefetcher(urls: urls).start()
        }
    }
    
    // called when a row leaves visibility
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cast cell and cancel download task if it is ongoing
        if let gameCell = cell as? GamesTableViewCell {
            gameCell.boxArt.kf.cancelDownloadTask()
        }
    }
    
    // enables and handles actions for swiping right on a cell
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let game = GameManager.instance.getGameForRow(atIndex: indexPath.row) else { return nil }
        
        let title = game.favorited ? NSLocalizedString("Remove", comment: "Remove from favorites") : NSLocalizedString("Add", comment: "Add to favorites")
        
        let action = UIContextualAction(style: .normal, title: title, handler: { (action, view, completionHandler) in
            print("Trailing swipe action taken")
            
            let cell = tableView.cellForRow(at: indexPath) as! GamesTableViewCell
            cell.favoritedImage.isHidden = !game.favoriteActionTaken()
            
            completionHandler(true)
        })

        action.backgroundColor = game.favorited ? .systemRed : .systemGreen
        action.image = UIImage(systemName: "star.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [action])
        
        return configuration
    }
    
    // context menu
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // game validation and context configuration
        let index = indexPath.row
        guard let game = GameManager.instance.getGameForRow(atIndex: index) else { return nil }
        let cell = tableView.cellForRow(at: indexPath) as! GamesTableViewCell
        
        let identifier = "\(index)" as NSString
        
        // build a new viewcontroller containing the box art for the context menu preview
        let boxArtPreviewController = UIViewController()
        let boxArtPreviewImageView = UIImageView(image: cell.boxArt.image)
        
        boxArtPreviewController.view = boxArtPreviewImageView
        boxArtPreviewImageView.translatesAutoresizingMaskIntoConstraints = true
        boxArtPreviewController.preferredContentSize = boxArtPreviewImageView.frame.size
        
        // deliver the configuration for the context menu with all necessary functionality through callbacks
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: { return boxArtPreviewController }) { _ in
            // build action for opening the game detail view
            let openAction = UIAction(title: "Open", image: UIImage(systemName: "list.bullet.below.rectangle")) { _ in
                self.performSegue(withIdentifier: "viewGameDetails", sender: game)
            }
            
            // build action for adding/removing game from favorites
            let favoritesText = game.favorited ? "Remove from favorites" : "Add to favorites"
            let favoriteAction = UIAction(title: favoritesText, image: UIImage(systemName: "star.fill")) { _ in
                cell.favoritedImage.isHidden = !game.favoriteActionTaken()
            }
            
            // build action for sharing game website
            let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                // build the link and then open the Share view
                if let myWebsite = game.getGameUrl() {
                    // build the menu
                    let objectsToShare = [myWebsite] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    
                    // present to the view
                    activityVC.popoverPresentationController?.sourceView = self.view
                    self.present(activityVC, animated: true, completion: nil)
                }
                else {
                    print("Failed to retrieve game URL")
                }
            }

            return UIMenu(title: game.listing.title, image: cell.boxArt.image, options: .displayInline, children: [openAction, favoriteAction, shareAction])
        }
    }

    // for helping with dynamically sized table cell heights
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // quickly scroll to the top of the table
    func scrollToTop() {
        if self.isViewLoaded && self.view.window != nil {
            let top = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: top, at: .top, animated: true)
        }
    }
    
    // action for sort button in the nav bar being selected
    @IBAction func sortNavBarButtonTapped(_ sender: Any) {
        // generate the action sheet for selecting sort type
        
        // get the active sort type to setup the selected action sheet option
        let sort = GameManager.instance.getSort()
        
        // build the sheet
        let item1 = SingleSelectItem(title: Config.Sorting.featured.label, subtitle: nil, isSelected: (sort == Config.Sorting.featured ? true : false), group: "sortOption", value: Config.Sorting.featured, image: nil, tapBehavior: .dismiss)
        let item2 = SingleSelectItem(title: Config.Sorting.releaseDate.label, subtitle: nil, isSelected: (sort == Config.Sorting.releaseDate ? true : false), group: "sortOption", value: Config.Sorting.releaseDate, image: nil, tapBehavior: .dismiss)
        let item3 = SingleSelectItem(title: Config.Sorting.titleAtoZ.label, subtitle: nil, isSelected: (sort == Config.Sorting.titleAtoZ ? true : false), group: "sortOption", value: Config.Sorting.titleAtoZ, image: nil, tapBehavior: .dismiss)
        let item4 = SingleSelectItem(title: Config.Sorting.titleZtoA.label, subtitle: nil, isSelected: (sort == Config.Sorting.titleZtoA ? true : false), group: "sortOption", value: Config.Sorting.titleZtoA, image: nil, tapBehavior: .dismiss)
        let item5 = SingleSelectItem(title: Config.Sorting.priceAscending.label, subtitle: nil, isSelected: (sort == Config.Sorting.priceAscending ? true : false), group: "sortOption", value: Config.Sorting.priceAscending, image: nil, tapBehavior: .dismiss)
        let item6 = SingleSelectItem(title: Config.Sorting.priceDescending.label, subtitle: nil, isSelected: (sort == Config.Sorting.priceDescending ? true : false), group: "sortOption", value: Config.Sorting.priceDescending, image: nil, tapBehavior: .dismiss)
        let cancel = CancelButton(title: "Cancel")
        
        let items = [item1, item2, item3, item4, item5, item6, cancel]
        let menu = Menu(title: "Sort by", items: items)
        
        // create the action sheet
        let actionSheet = ActionSheet(menu: menu, configuration: .backgroundDismissable) { sheet, item in
            // iterate through the selected values and set the new sort type
            if let selected = item.value as? Config.Sorting {
                switch selected {
                case .featured:
                    print("Sorting by featured")
                    if GameManager.instance.setSort(to: Config.Sorting.featured) {
                        self.tableView.reloadData()
                        self.scrollToTop()
                    }
                    
                case .releaseDate:
                    print("Sorting by release date")
                    if GameManager.instance.setSort(to: Config.Sorting.releaseDate) {
                        self.tableView.reloadData()
                        self.scrollToTop()
                    }
                    
                case .titleAtoZ:
                    print("Sorting by title (ascending)")
                    if GameManager.instance.setSort(to: Config.Sorting.titleAtoZ) {
                        self.tableView.reloadData()
                        self.scrollToTop()
                    }
                    
                case .titleZtoA:
                    print("Sorting by title (descending)")
                    if GameManager.instance.setSort(to: Config.Sorting.titleZtoA) {
                        self.tableView.reloadData()
                        self.scrollToTop()
                    }
                    
                case .priceAscending:
                    print("Sorting by price (ascending)")
                    if GameManager.instance.setSort(to: Config.Sorting.priceAscending) {
                        self.tableView.reloadData()
                        self.scrollToTop()
                    }
                    
                case .priceDescending:
                    print("Sorting by price (descending)")
                    if GameManager.instance.setSort(to: Config.Sorting.priceDescending) {
                        self.tableView.reloadData()
                        self.scrollToTop()
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
    
    // navbar button is touched for filtering games
    @IBAction func filterNavBarButtonTouched(_ sender: Any) {
        // start building the menu
        var items = [MenuItem]()
        guard let currentFilter = GameManager.instance.getCurrentFilter() else {
            print("Failed to get the current filter")
            return
        }
        
        // general filters section
        let generalTitle = SectionTitle(title: "General")
        items.append(generalTitle)
        
        // iterate through general filters and build a MultiSelect menu item
        for key in currentFilter.general.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.general.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.general, key: key), group: Config.FilterGroup.general, value: key, image: nil)
            
            // disable selection if this filter results in an empty table (0 results if selected)
            if currentFilter.general.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            
            // add to the items array which is used to build the Menu
            items.append(menuItem)
        }

        // create the generic section margin object to be added between each filter type
        let sectionMargin = SectionMargin()
        items.append(sectionMargin)

        // availability filters section
        let availabilityTitle = SectionTitle(title: "Availability")
        items.append(availabilityTitle)

        for key in currentFilter.availability.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.availability.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.availability, key: key), group: Config.FilterGroup.availability, value: key, image: nil)
            if currentFilter.availability.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        items.append(sectionMargin)

        // price range filters section
        let priceRangeTitle = SectionTitle(title: "Price Range")
        items.append(priceRangeTitle)

        for key in currentFilter.priceRange.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.priceRange.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.priceRange, key: key), group: Config.FilterGroup.priceRange, value: key, image: nil)
            if currentFilter.priceRange.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        items.append(sectionMargin)

        // players filters section
        let playersTitle = SectionTitle(title: "Players")
        items.append(playersTitle)

        for key in currentFilter.players.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.players.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.players, key: key), group: Config.FilterGroup.players, value: key, image: nil)
            if currentFilter.players.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        items.append(sectionMargin)

        // genres filters section
        let genresTitle = SectionTitle(title: "Genres")
        items.append(genresTitle)

        for key in currentFilter.genres.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.genres.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.genres, key: key), group: Config.FilterGroup.genres, value: key, image: nil)
            if currentFilter.genres.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        items.append(sectionMargin)

        // characters filters section
        let charactersTitle = SectionTitle(title: "Characters")
        items.append(charactersTitle)

        for key in currentFilter.franchises.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.franchises.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.franchises, key: key), group: Config.FilterGroup.franchises, value: key, image: nil)
            if currentFilter.franchises.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        items.append(sectionMargin)

        // esrb rating filters section
        let esrbRatingTitle = SectionTitle(title: "ESRB Rating")
        items.append(esrbRatingTitle)

        for key in currentFilter.esrbRating.keys {
            let menuItem = MultiSelectItem(title: ("  \(key) (\(currentFilter.esrbRating.filter[key]!))"), subtitle: nil, isSelected: GameManager.instance.isFilterActive(group: Config.FilterGroup.esrbRating, key: key), group: Config.FilterGroup.esrbRating, value: key, image: nil)
            if currentFilter.esrbRating.filter[key]! == 0 {
                menuItem.isEnabled = false
            }
            items.append(menuItem)
        }

        // create the clear all button
        let clear = DestructiveButton(title: "Clear all filters")
        clear.tapBehavior = .none
        
        // if there are no active filters, disable the button
        if GameManager.instance.activeFilterCount() == 0 {
            clear.isEnabled = false
        }
        items.append(clear)

        // create the default, "OK" button
        let cancel = OkButton(title: "Done")
        items.append(cancel)

        // build the menu
        let menu = Menu(title: "Filter by", items: items)

        // create the action sheet
        let actionSheet = ActionSheet(menu: menu, configuration: .backgroundDismissable) { sheet, item in
            // check if a filter button was selected
            if let selected = item as? MultiSelectItem {
                if let key = selected.value as? String {
                    GameManager.instance.changeActiveFilter(group: selected.group, key: key, selected: selected.isSelected)
                }
            }
            // check if the clear all button was selected
            else if let _ = item as? DestructiveButton {
                // clear the active filters
                GameManager.instance.clearActiveFilters()
                
                // flip all of the buttons to false
                for item in items {
                    if let filterButton = item as? MultiSelectItem {
                        filterButton.isSelected = false
                    }
                }
            }
            else {
                // nothing needs to be done so exit this callback without doing the below menu update
                return
            }
            
            // update the titles for all of the menu items
            guard let filter = GameManager.instance.getCurrentFilter() else {
                return
            }
            
            // iterate through the menu items and update
            for item in sheet.items {
                if let item = item as? MultiSelectItem {
                    guard let key = item.value as? String else { break }
                    var itemCount: Int?
                    
                    switch item.group {
                    case Config.FilterGroup.general:
                        if let count = filter.general.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }

                    case Config.FilterGroup.availability:
                        if let count = filter.availability.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                    
                    case Config.FilterGroup.priceRange:
                        if let count = filter.priceRange.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                    
                    case Config.FilterGroup.players:
                        if let count = filter.players.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                        
                    case Config.FilterGroup.genres:
                        if let count = filter.genres.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                        
                    case Config.FilterGroup.franchises:
                        if let count = filter.franchises.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                        
                    case Config.FilterGroup.esrbRating:
                        if let count = filter.esrbRating.filter[key] {
                            item.title = "  \(key) (\(count))"
                            itemCount = count
                        }
                            
                    default:
                        print("Error: Invalid filter found somehow")
                    }
                    
                    // make sure we pulled a valid count from a filter
                    if let count = itemCount {
                        // now make sure we enable and disable the necessary menu items who should be tappable
                        if item.isEnabled {
                            // if currently enabled, check if we need to disable it
                            if count == 0 {
                                // filters that result in 0 games should be disabled
                                item.isEnabled = false
                            }
                        }
                        else {
                            // if disabled, check if we need to re-enable
                            if count > 0 {
                                // filters that result in more than 1 game are valid and should be tappable
                                item.isEnabled = true
                            }
                        }
                    }
                }
            }
            
            // now iterate the buttons to update the Clear All Filters button
            for button in sheet.buttons {
                if let clearAllButton = button as? DestructiveButton {
                    // check the current state
                    if clearAllButton.isEnabled {
                        // now check if we should enable or disable the clear all filters button
                        if GameManager.instance.activeFilterCount() == 0 {
                            clearAllButton.isEnabled = false
                        }
                    }
                    else {
                        // enable the button if necessary
                        if GameManager.instance.activeFilterCount() > 0 {
                            clearAllButton.isEnabled = true
                        }
                    }
                }
            }
            
            self.tableView.reloadData()
            self.scrollToTop()
        }

        // present the action sheet
        actionSheet.present(in: self, from: self.view)
    }
    
    // function call for executing a table refresh by pulling down at the top of the table
    @objc private func refreshGamesData(_ sender: Any) {
        self.refresh.beginRefreshing()
        
        DispatchQueue.global(qos: .background).async {
            // do a complete update from the api and save the new json
            GameManager.instance.retrieveGameUpdates() { (success, error, count) in
                if success {
                    if !GameManager.instance.saveGamesJSONFile() {
                        print("Save failed after data was updated from API")
                    }
            
                    // save to file and show the table, on the main thread
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.refresh.endRefreshing()
                    }
                }
                else {
                    DispatchQueue.main.async {
                        print("API update failed with \(String(describing: error))")
                        self.refresh.endRefreshing()
                    }
                }
            }
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        print("Searching for \(searchText)")
        GameManager.instance.searchTitlesFor(searchText)
        tableView.reloadData()
    }
    
    // determines if there are characters input into the search bar
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }

    // preparation before segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass along the game object for the cell that was selected
        if segue.identifier == "viewGameDetails" {
            if let destinationVC = segue.destination as? GameDetailsViewController {
                if let index = self.tableView.indexPathForSelectedRow?.row {
                    // if triggered from storyboard segue
                    destinationVC.game = GameManager.instance.getGameForRow(atIndex: index)
                }
                else if let game = sender as? Game {
                    // if manually triggered and game sent through as sender
                    destinationVC.game = game
                }
            }
        }
    }

}

// extension for including searchController funcitonality in the games table vc
extension GamesTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}
