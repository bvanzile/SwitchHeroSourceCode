//
//  GameDetailsViewController.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/21/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import SafariServices
import Kingfisher
import Sheeeeeeeeet
import Alamofire

class GameDetailsViewController: UIViewController, UIScrollViewDelegate {
    // for saving the scroll view to hide/show it while loading
    //var scrollView: UIScrollView?
    
    // this is the game object with the details to populate this view
    var game: Game?
    
    // table controller
    var detailsTable: GameDetailsTableViewController?
    
    // navigation bar items
    var favoritedTrueNavBarButton: UIBarButtonItem?
    var favoritedFalseNavBarButton: UIBarButtonItem?
    var optionsNavBarButton: UIBarButtonItem?
    
    // outlets from storyboard
    @IBOutlet weak var galleryScrollView: UIScrollView!
    @IBOutlet weak var galleryPageControl: UIPageControl!
    @IBOutlet weak var saleTagImageView: UIImageView!
    @IBOutlet weak var saleTagLabel: UILabel!
    @IBOutlet weak var esrbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var availabilityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionButton: UIButton!
    @IBOutlet weak var eShopButton: RoundButton!
    
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func loadView() {
        print("GameDetailsViewController->loadView()")
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("GameDetailsViewController->viewDidLoad()")
        
        // unwrap the game that was passed through the segue
        if game != nil {
            self.title = game!.listing.title

            // hide scroll view while we load the game
            self.scrollView.isHidden = true
            
            // create a temporary activity indicator to display while loading the page
            let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
            
            activityIndicator.startAnimating()
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.restorationIdentifier = "activityIndicator"
            
            // add to the current view and set constraints
            self.view.addSubview(activityIndicator)
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

            // set up the custom favorited navigation bar button for games on the favorites list
            let favoriteTrueButton = UIButton(type: .custom)
            favoriteTrueButton.setImage(Config.FavoritesNavBarImage.iconTrue, for: .normal)
            favoriteTrueButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            favoriteTrueButton.addTarget(self, action: #selector(handleFavoriteButtonTouched(_:)), for: .touchUpInside)

            // create the nav bar item with custom view and layout
            self.favoritedTrueNavBarButton = UIBarButtonItem(customView: favoriteTrueButton)
            var resizedFrame = self.favoritedTrueNavBarButton!.customView!.frame
            resizedFrame.size.width = 30
            self.favoritedTrueNavBarButton!.customView!.frame = resizedFrame

            // set up the custom favorited navigation bar button for games not on the favorites list
            let favoriteFalseButton = UIButton(type: .custom)
            favoriteFalseButton.setImage(Config.FavoritesNavBarImage.iconFalse, for: .normal)
            favoriteFalseButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            favoriteFalseButton.addTarget(self, action: #selector(handleFavoriteButtonTouched(_:)), for: .touchUpInside)

            // create the nav bar item with custom view and layout
            self.favoritedFalseNavBarButton = UIBarButtonItem(customView: favoriteFalseButton)
            resizedFrame = self.favoritedFalseNavBarButton!.customView!.frame
            resizedFrame.size.width = 30
            self.favoritedFalseNavBarButton!.customView!.frame = resizedFrame

            // set up the options navigation bar button
            let optionsButton = UIButton(type: .custom)
            optionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
            optionsButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            optionsButton.addTarget(self, action: #selector(optionsButtonTouched(_:)), for: .touchUpInside)

            // create the custom view/layout/callback
            self.optionsNavBarButton = UIBarButtonItem(customView: optionsButton)
            resizedFrame = self.optionsNavBarButton!.customView!.frame
            resizedFrame.size.width = 30
            self.optionsNavBarButton!.customView!.frame = resizedFrame

            // save and then set the navigation bar buttons to the navigation bar
            self.setNavBar(isFavorited: self.game!.favorited)

            // trigger layout update for the navigation bar item resizes
            self.view.setNeedsLayout()

            // page control setup (hero image + gallery images)
            galleryPageControl.numberOfPages = 1

            // for making gallery image and hero image calls asynchronously
            let dispatchGroup = DispatchGroup()

            // for storing future gallery images
            var galleryImages = [Int: UIImage]()

            // for storing the hero image or default image
            let heroImageView = UIImageView()
            
            print("Nsuid: \(game!.listing.nsuid)")

            // at this point, the storyboard view is hidden and an activity indicator is spinning while we set up the view
            // call games api to retrieve game details
            if let gameApiUrl = URL(string: "\(Config.GamesAPI.url)\(Config.GamesAPI.resourceNsuid)\(game!.listing.nsuid)") {
                // request full game details from api
                AF.request(gameApiUrl, method: .get).response { (response) in
                    // check if the call failed
                    if let error = response.error {
                        print("Error when calling \(gameApiUrl): \(error.localizedDescription)")
                        
                        // do something for failures
                    }
                    // try to unpack the response data from url call
                    else if let data = response.data {
                        do {
                            // decode dynamodb json as game response
                            let decoder = JSONDecoder()
                            let gameData = try decoder.decode(DynamoGameDetailsData.self, from: data)
                            
                            // pull out full details from json response
                            if let details = gameData.Items {
                                if details.count > 0 {
                                    if let fullDetails = GameDetails(details[0]) {
                                        self.game!.fullDetails = fullDetails
                                        
                                        // build the url to get the hero image from nintendo
                                        if let heroUrl = URL(string: "\(Config.nintendoUrl)\(fullDetails.horizontalHeaderImage)") {
                                            // kick off first call for hero image
                                            dispatchGroup.enter()

                                            // make a call to nintendo for the hero image and then set it
                                            heroImageView.kf.setImage(with: heroUrl, completionHandler: { result in
                                                switch result {
                                                case .success(let value):
                                                    print("Hero image retrieved from cache type: \(value.cacheType)")

                                                    // completed with successful retrieval of hero image
                                                    dispatchGroup.leave()

                                                case .failure(_):
                                                    print("Error retrieving hero image from \(heroUrl)")

                                                    // no hero image so lets just set it to the box art
                                                    if let boxArtUrl = self.game!.getBoxArtUrl() {
                                                        heroImageView.kf.indicatorType = .activity
                                                        heroImageView.kf.setImage(with: boxArtUrl, completionHandler: { result in
                                                            switch result {
                                                            case .success(let value):
                                                                print("Box art retrieved from cache type: \(value.cacheType)")

                                                            case .failure(_):
                                                                print("Error retrieving hero image from \(boxArtUrl)")

                                                                // if even the boxart fails, set to default
                                                                heroImageView.image = UIImage(named: "switchLogoBanner")
                                                            }

                                                            // completed with backup plan
                                                            dispatchGroup.leave()
                                                        })
                                                    }
                                                }
                                            })
                                        }
                                        else {
                                            // this should never be called
                                            print("Invalid url for getting hero image @\(fullDetails.horizontalHeaderImage)")

                                            // set to default
                                            heroImageView.image = UIImage(named: "switchLogoBanner")
                                        }

                                        // start retrieving the gallery images for the carousel
                                        for (index, url) in fullDetails.gallery.enumerated() {
                                            // build the url to get the gallery image from nintendo
                                            if let galleryUrl = URL(string: Config.nintendoUrl + url) {
                                                // kick off first call for hero image
                                                dispatchGroup.enter()

                                                // gallery image
                                                let galleryImage = UIImageView()

                                                // make a call to nintendo for the hero image and then set it
                                                galleryImage.kf.setImage(with: galleryUrl, completionHandler: { result in
                                                    switch result {
                                                    case .success(let value):
                                                        print("Gallery image \(index+1) retrieved from cache type: \(value.cacheType)")
                                                        if let image = galleryImage.image {
                                                            galleryImages[index] = image
                                                        }

                                                    case .failure(_):
                                                        print("Error retrieving hero image \(index+1) from \(galleryUrl)")
                                                    }

                                                    // completed
                                                    dispatchGroup.leave()
                                                })
                                            }
                                        }

                                        // all dispatch have returned, continue setting up the view
                                        dispatchGroup.notify(queue: .main, execute: {
                                            // count of how many page controled images that are available for the image carousel
                                            var galleryCount = 0

                                            // reusable frame for generating the long image carousel
                                            var frame = CGRect.zero

                                            // set up the hero image first
                                            if heroImageView.image != nil {
                                                // set up the image framing
                                                frame.origin.x = 0
                                                frame.size = self.galleryScrollView.frame.size

                                                // copy over the image
                                                let imgView = UIImageView(frame: frame)
                                                imgView.contentMode = .scaleAspectFit
                                                imgView.image = heroImageView.image

                                                // add subview
                                                self.galleryScrollView.addSubview(imgView)

                                                // first image added
                                                galleryCount += 1
                                            }

                                            // iterate through the captured gallery images
                                            for i in 0..<fullDetails.gallery.count {
                                                if let image = galleryImages[i] {
                                                    frame.origin.x = self.galleryScrollView.frame.size.width * CGFloat(galleryCount)
                                                    frame.size = self.galleryScrollView.frame.size

                                                    // copy over the image
                                                    let imgView = UIImageView(frame: frame)
                                                    imgView.image = image

                                                    // add subview
                                                    self.galleryScrollView.addSubview(imgView)

                                                    // first image added
                                                    galleryCount += 1
                                                }
                                            }

                                            // finish setting up the gallery image carousel
                                            self.galleryScrollView.contentSize = CGSize(width: (self.galleryScrollView.frame.size.width * CGFloat(galleryCount)), height: self.galleryScrollView.frame.size.height)
                                            self.galleryScrollView.delegate = self

                                            // page control setup (hero image + gallery images)
                                            self.galleryPageControl.numberOfPages = galleryCount
                                            
                                            // fix gallery color for light userInterfaceStyle
                                            if Config.Settings.getInterfaceStyle() == .light {
                                                self.galleryPageControl.pageIndicatorTintColor = .systemGray4
                                                self.galleryPageControl.currentPageIndicatorTintColor = .black
                                            }
                                            
                                            // hide or setup the sale tag
                                            if fullDetails.onSale && fullDetails.msrp > 0 && fullDetails.salePrice >= 0 {
                                                self.saleTagLabel.text = "-\(Int((1 - (fullDetails.salePrice / fullDetails.msrp)) * 100))%"
                                            }
                                            else {
                                                // hide image and label
                                                self.saleTagImageView.isHidden = true
                                                self.saleTagLabel.isHidden = true
                                            }

                                            // get the right esrb image or hide it if it fails somehow
                                            if let esrbImage = self.game!.getESRBImage() {
                                                self.esrbImageView.image = esrbImage
                                            }
                                            else {
                                                self.esrbImageView.isHidden = true
                                            }

                                            self.titleLabel.text = fullDetails.title
                                            if self.game!.releaseDate == nil {
                                                self.availabilityLabel.text = "Available \(self.game!.availabilityString)"
                                            }
                                            else {
                                                self.availabilityLabel.text = self.game!.availabilityString
                                            }
                                            self.priceLabel.attributedText = self.game!.getAttributedPriceString(fontSize: 20)
                                            self.descriptionLabel.attributedText = self.game!.getDescription() ?? NSAttributedString(string: "No description available.")

                                            // determine if the "See more" button is required by comparing the label size before and after adjusting the view with the default number of lines
                                            self.view.layoutIfNeeded()

                                            // check if the description is short enough to not require expansion button
                                            if let maxHeight = self.descriptionLabel?.bounds.size.height {
                                                // now limit lines to the default value and update view
                                                self.descriptionLabel.numberOfLines = Config.GameDefaults.descriptionNumberOfLines
                                                self.view.layoutIfNeeded()

                                                // hide the description button if limiting the lines to default resulted in no change
                                                if self.descriptionLabel.bounds.size.height == maxHeight {
                                                    self.descriptionButton.isHidden = true
                                                }
                                            }
                                            
                                            // populate the details table with the full game details
                                            self.detailsTable?.populateDetailsTable(self.game!)
                                            self.detailsTable?.tableView.reloadData()

                                            activityIndicator.stopAnimating()
                                            activityIndicator.removeFromSuperview()

                                            self.scrollView?.isHidden = false
                                        })
                                    }
                                }
                                else {
                                    print("Bad data, no game found")
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
                        }
                        catch let parseError {
                            print("JSON Error: \(parseError)")
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    else {
                        print("Bad data but also no error?")
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
        else {
            // invalid game somehow, return to root
            self.title = ""

            // hide scroll view while we load the game
            self.scrollView.isHidden = true
            
            // create a temporary activity indicator to display while loading the page
            let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
            
            activityIndicator.startAnimating()
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.restorationIdentifier = "activityIndicator"
            
            // add to the current view and set constraints
            self.view.addSubview(activityIndicator)
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("GameDetailsViewController->viewWillAppear(animated = \(animated))")
        super.viewWillAppear(animated)

        // adjust the favorites nav bar icon, if necessary
        self.setNavBar(isFavorited: (self.game?.favorited ?? false))
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = self.galleryScrollView.contentOffset.x / self.galleryScrollView.frame.size.width
        galleryPageControl.currentPage = Int(pageNumber)
    }
    
    // re-adjusts the top right navigation bar icons based on if the game is on the favorites list or not
    func setNavBar(isFavorited: Bool) {
        if self.optionsNavBarButton != nil && self.favoritedFalseNavBarButton != nil && self.favoritedTrueNavBarButton != nil {
            // replace with the correct buttons
            self.navigationItem.setRightBarButtonItems([self.optionsNavBarButton!, isFavorited ? self.favoritedTrueNavBarButton! : self.favoritedFalseNavBarButton!], animated: false)
        }
    }
    
    // favorite navigation bar button was touched
    @objc func handleFavoriteButtonTouched(_ sender: Any) {
        if game != nil {
            // update the nav bar icon while changing the game object
            if self.game!.favoriteActionTaken() {
                self.setNavBar(isFavorited: true)
                print("\(self.game!.listing.title) added to favorites")
            }
            else {
                self.setNavBar(isFavorited: false)
                print("\(self.game!.listing.title) removed from favorites")
            }
        }
    }
    
    // options (...) navigation bar button was touched
    @objc func optionsButtonTouched(_ sender: Any) {
        if let isFavorited = self.game?.favorited {
            // make the first action sheet item based on whether this game is on the favorites or not
            let item1: MenuItem
            if isFavorited {
                item1 = MenuItem(title: "Remove from favorites", subtitle: nil, value: Config.GameOptionsMenu.favoritesRemove, image: UIImage(systemName: "star.fill"), isEnabled: true, tapBehavior: .dismiss)
            }
            else {
                item1 = MenuItem(title: "Add to favorites", subtitle: nil, value: Config.GameOptionsMenu.favoritesAdd, image: UIImage(systemName: "star.fill"), isEnabled: true, tapBehavior: .dismiss)
            }
            
            // add buttons for the eshop and share options
            let item2 = MenuItem(title: "Open eShop link", subtitle: nil, value: Config.GameOptionsMenu.eShopInternalBrowser, image: UIImage(systemName: "link"), isEnabled: true, tapBehavior: .dismiss)
            let item3 = MenuItem(title: "Open link in Safari browser", subtitle: nil, value: Config.GameOptionsMenu.eShopExternalSafari, image: UIImage(systemName: "link"), isEnabled: true, tapBehavior: .dismiss)
            let item4 = MenuItem(title: "Share", subtitle: nil, value: Config.GameOptionsMenu.share, image: UIImage(systemName: "square.and.arrow.up"), isEnabled: true, tapBehavior: .dismiss)
            
            // default cancel button at the bottom of the menu
            let cancel = CancelButton(title: "Cancel")
            
            // build the menu object
            let items = [item1, item2, item3, item4, cancel]
            let menu = Menu(items: items)
            
            // create the action sheet
            let actionSheet = ActionSheet(menu: menu, configuration: .backgroundDismissable) { sheet, item in
                // execute the action based on which item was pressed
                if let selected = item.value as? Config.GameOptionsMenu {
                    switch selected {
                    case .favoritesRemove:
                        print("Removing from favorites")
                        
                        // adjust the favorite nav bar image based on what was changed
                        self.setNavBar(isFavorited: self.game!.favoriteActionTaken())
                        
                    case .favoritesAdd:
                        print("Adding to favorites")
                        
                        // adjust the favorite nav bar image based on what was changed
                        self.setNavBar(isFavorited: self.game!.favoriteActionTaken())
                        
                    case .eShopInternalBrowser:
                        print("Opening in the in-app browser")
                        
                        if let url = self.game?.getGameUrl() {
                            let config = SFSafariViewController.Configuration()

                            let vc = SFSafariViewController(url: url, configuration: config)
                            self.present(vc, animated: true)
                        }
                        else {
                            // TODO: show message popup
                            print("Failed to open game url")
                        }
                        
                    case .eShopExternalSafari:
                        print("Opening in Safari")
                        
                        if let url = self.game?.getGameUrl() {
                             UIApplication.shared.open(url)
                        }
                        
                    case .share:
                        print("Opening the share menu")
                        
                        // build the link and then open the Share view
                        if let myWebsite = self.game?.getGameUrl() {
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
                }
                else {
                    print("Non-action selected: \(item.value ?? "nil")")
                }
            }
            
            // display the action sheet
            actionSheet.present(in: self, from: self.view)
        }
    }
    
    @IBAction func pageControlChanged(_ sender: Any) {
        var frame = self.galleryScrollView.frame
        frame.origin.x = frame.size.width * CGFloat(self.galleryPageControl.currentPage)
        frame.origin.y = 0
        self.galleryScrollView.scrollRectToVisible(frame, animated: true)
    }
    
    @IBAction func eShopButtonTouched(_ sender: Any) {
        if let url = self.game?.getGameUrl() {
            let config = SFSafariViewController.Configuration()

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
        else {
            // TODO: show message popup
            print("Failed to open game url")
        }
    }
    
    @IBAction func descriptionButtonTouched(_ sender: Any) {
        if self.descriptionLabel.numberOfLines == 0 {
            UIView.transition(with: self.descriptionLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.descriptionLabel.numberOfLines = Config.GameDefaults.descriptionNumberOfLines
                self.descriptionButton.setTitle("See more", for: .normal)
            })
        }
        else {
            UIView.transition(with: self.descriptionLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.descriptionLabel.numberOfLines = 0
                self.descriptionButton.setTitle("See less", for: .normal)
            })
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if let child = container as? GameDetailsTableViewController {
            tableHeightConstraint.constant = child.preferredContentSize.height
            tableContainerView.updateConstraints()
        }
    }
    
    // segue for adding the table controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let childViewController = segue.destination as? GameDetailsTableViewController {
            addChild(childViewController)
            
            // capture the controller to update the table
            self.detailsTable = childViewController
        }
    }
}
