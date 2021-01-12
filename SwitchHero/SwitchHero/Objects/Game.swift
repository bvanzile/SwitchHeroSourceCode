//
//  GameDetails.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/22/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import UIKit
import Foundation
import Kingfisher

class Game: Equatable {
    // the game details from the API or JSON file
    var listing: GameListing
    
    // full game details, if passed in
    var fullDetails: GameDetails?
    
    // release date as object
    var releaseDate: Date?
    
    // game availability text for the details page
    let availabilityString: String
    
    // the active price (used for sorting so defaults to 9999)
    let ascendingSortPrice: Double
    let descendingSortPrice: Double
    
    // percentage off msrp if the game is on sale
    var percentOff: Int?
    
    // track if this game is on the favorites list
    var favorited: Bool
    
    // initializing based on game listing from either API call to DynamoDB or from reading local JSON
    init?(game: Any) {
        // retrieve the game details from the passed in paramater
        if let dynamoDetails = game as? DynamoGameShortInfo {
            if let gameListing = GameListing(dynamoDetails) {
                self.listing = gameListing
            }
            else {
                print("Failed to create game from DynamoGameDetails: (Title: \(dynamoDetails.title?.S ?? "nil"))")
                return nil
            }
        }
        else if let gameDetails = game as? GameListing {
            self.listing = gameDetails
        }
        else {
            print("Failed to cast game from paramater game object")
            return nil
        }
        
        // start initializing game object from the passed in listing
        if self.listing.nsuid != 0 {
            // get the release date in the right format
            if self.listing.releaseDateDisplay != "" {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = Config.GameDefaults.dateInputFormat
                
                // trying to get format for example (skyrim) 2017-11-16T00:00:00.000-08:00
                self.releaseDate = dateFormatter.date(from: self.listing.releaseDateDisplay)
                
                // check if it worked
                if self.releaseDate == nil {
                    // try the other format games can come in, example (super meat boy) 2018-01-11T00:00:00.000Z
                    dateFormatter.dateFormat = Config.GameDefaults.dateInputFormat2
                    self.releaseDate = dateFormatter.date(from: self.listing.releaseDateDisplay)
                }
                
                // check if formatting was successful
                if self.releaseDate == nil {
                    // set the availability to the release date mask since it should be a custom release date message
                    self.availabilityString = self.listing.releaseDateDisplay
                }
                // it was a success
                else {
                    // compare release date to today to build availability string
                    if releaseDate! < Date() {
                        // already released
                        self.availabilityString = Config.GameDefaults.availableNow
                    }
                    else {
                        // get the release date in a printable format
                        let listingDateFormat = DateFormatter()
                        listingDateFormat.dateFormat = Config.GameDefaults.dateListingFormat
                        
                        self.availabilityString = Config.GameDefaults.releasePrefix + listingDateFormat.string(from: releaseDate!)
                    }
                }
            }
            else {
                self.releaseDate = nil
                self.availabilityString = Config.GameDefaults.blankReleaseDateDefaultText
            }
            
            // get the active price so this game is sortable
            if self.listing.hasPrice {
                if self.listing.onSale {
                    self.ascendingSortPrice = self.listing.salePrice
                    self.descendingSortPrice = self.listing.salePrice
                    
                    // if the game is on sale, grab the sale percentage off msrp here
                    if self.listing.msrp > 0, self.listing.salePrice > 0 {
                        self.percentOff = Int(((self.listing.msrp - self.listing.salePrice) / self.listing.msrp) * -100)
                    }
                }
                else {
                    self.ascendingSortPrice = self.listing.msrp
                    self.descendingSortPrice = self.listing.msrp
                }
            }
            else {
                // defaults so that it always comes up last
                self.ascendingSortPrice = 9999
                self.descendingSortPrice = -9999
            }
            
            // check if this game is favorited
            self.favorited = GameManager.instance.isFavorited(self.listing.nsuid)
        }
        else {
            print("Failed to create game from GameDetails: (Title: \(self.listing.title))")
            return nil
        }
    }
    
    func getAttributedPriceString(fontSize: CGFloat) -> NSMutableAttributedString {
        // return value we will build
        let priceAttributedString: NSMutableAttributedString
        
        // build the attributed price string used in a few places
        var msrpString: String = ""
        var saleString: String?
        
        if self.listing.hasPrice {
            if self.listing.onSale {
                msrpString = "$\(String(format: "%.2f", self.listing.msrp))"
                saleString = "$\(String(format: "%.2f", self.listing.salePrice))"
            }
            else if self.listing.msrp == 0.0 {
                msrpString = "Free"
            }
            else {
                msrpString = "$\(String(format: "%.2f", self.listing.msrp))"
            }
        }
        else {
            msrpString = "Pricing unavailable"
        }
        
        // unwrap the sale string if we ever wrote to it
        if let saleString = saleString {
            let priceString = saleString + " " + msrpString
            priceAttributedString = NSMutableAttributedString(string: priceString)
            
            // setup the bold sale price
            priceAttributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: fontSize), range: NSRange(location: 0, length: saleString.count))
            
            // setup the strikethrough msrp
            if let range: Range<String.Index> = priceString.range(of: msrpString) {
                let index: Int = priceString.distance(from: priceString.startIndex, to: range.lowerBound)
                priceAttributedString.addAttribute(.strikethroughStyle, value: 1, range: NSRange(location: index, length: msrpString.count))
            }
        }
        else {
            // If no sale, just use the msrp string
            priceAttributedString = NSMutableAttributedString(string: msrpString)
        }

        return priceAttributedString
    }
    
    // map the esrb value from the API to the image asset in xcode
    func getESRBImage() -> UIImage? {
        var esrbImage: UIImage?
        
        switch self.listing.esrbRating {
        case Config.ESRB.fromAPI.e:
            esrbImage = UIImage(named: Config.ESRB.imageString.e)
        case Config.ESRB.fromAPI.e10:
            esrbImage = UIImage(named: Config.ESRB.imageString.e10)
        case Config.ESRB.fromAPI.t:
            esrbImage = UIImage(named: Config.ESRB.imageString.t)
        case Config.ESRB.fromAPI.m:
            esrbImage = UIImage(named: Config.ESRB.imageString.m)
        default:
            esrbImage = nil
        }
        
        return esrbImage
    }
    
    // get box art url object
    func getBoxArtUrl() -> URL? {
        return URL(string: Config.nintendoUrl + self.listing.boxart)
    }
    
    // get game url, which is only available in the full details
    func getGameUrl() -> URL? {
        if self.fullDetails == nil {
            return nil
        }
        else {
            return URL(string: Config.nintendoUrl + self.fullDetails!.url)
        }
    }
    
    // get the game description as attributed string from HTML
    func getDescription() -> NSMutableAttributedString? {
        // make sure game contains a description in the full details
        if let description = fullDetails?.description {
            // add font to the string before the html parser converts it to attributed string
            let htmlModifiedFont = String(format: "<span style=\"font-family: '-apple-system'; font-size: 12\">%@</span>", description)
            
            // parse html into attributed string
            if var attrStr = try? NSMutableAttributedString(data: htmlModifiedFont.data(using: .unicode, allowLossyConversion: true)!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
                // add the default label color
                attrStr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: attrStr.length))
                
                // chop off last newline to make sure it lines up well with labels below
                if attrStr.string.hasSuffix("\n") {
                    attrStr = attrStr.attributedSubstring(from: NSMakeRange(0, attrStr.length - 1)) as! NSMutableAttributedString
                }
                
                // edit the bullet paragraphStyle with better looking options (also iOS bug with display and numOfLines)
                attrStr.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attrStr.length), options: []) { (value, range, stop) -> Void in
                    if let attr = value as? NSMutableParagraphStyle {
                        // bullet attribute has an indent
                        if attr.headIndent > 0 {
                            // create paragraphStyle to swap for better bullets
                            let style = NSMutableParagraphStyle()
                            style.paragraphSpacing = 8
                            style.defaultTabInterval = 25
                            style.headIndent = 25
                            style.tabStops = [NSTextTab(textAlignment: .left, location: 11), NSTextTab(textAlignment: .natural, location: 25)]

                            // make the swap
                            attrStr.removeAttribute(.paragraphStyle, range: range)
                            attrStr.addAttribute(.paragraphStyle, value: style, range: range)
                        }
                    }
                }
                
                return attrStr
            }
        }
        
        return nil
    }
    
    // action taken when the favorite action is taken on one of the tables, returns new favorite state
    func favoriteActionTaken() -> Bool {
        // reverse the favorite bool
        self.favorited = !self.favorited
        
        // update the game manager
        if self.favorited {
            if !GameManager.instance.addToFavorites(self) {
                print("Adding \(self.listing.title) to favorites failed")
            }
        }
        else {
            if !GameManager.instance.removeFromFavorites(self) {
                print("Removing \(self.listing.title) from favorites failed")
            }
        }
        
        print("\(self.listing.title): isFavorited = \(self.favorited)")
        return self.favorited
    }
    
    // satisfy Equatable constraints
    static func ==(lhs: Game, rhs: Game) -> Bool {
        return lhs.listing.nsuid == rhs.listing.nsuid
    }
}

