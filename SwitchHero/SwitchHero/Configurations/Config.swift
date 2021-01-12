//
//  Config.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/23/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation
import UIKit

class Config {
    // local file name for game JSON
    static let localJsonFilename: String = "games"
    
    // base URL for acquiring content from Nintendo
    static let nintendoUrl: String = "https://www.nintendo.com"
    // nintendo.com wish list url
    static let nintendoWishListUrl: String = "https://www.nintendo.com/wish-list/"
    
    // identifier for the favorites array saved to UserDefaults
    struct SavedUserData {
        static let favorites = "Favorites.Games.Array"
    }
    
    // string values for the title of each of the 3 tabs
    struct TabTitle {
        static let first = "Games"
        static let second = "Favorites"
        static let third = "Settings"
    }
    
    // keys for the settings that are saved into UserDefaults
    struct Settings {
        // General
        static let localNotifications = "Settings.Notifications.LocalNotifications"
        
        // Appearance
        static let useSystemMode = "Settings.Appearance.UseSystemMode"              // contains Bool
        static let appearanceMode = "Settings.Appearance.AppearanceMode"            // contains String -> self.AppearanceModes
        static let favoritesBadgeCount = "Settings.Appearance.FavoritesBadgeCount"  // contains Bool
        static let highlightDeals = "Settings.Appearance.HighlightDeals"            // contains Bool
        
        // labels and string for UserDefaults appearanceMode
        struct AppearanceModes {
            static let darkMode = "Dark Mode"
            static let lightMode = "Light Mode"
        }
        
        // get the current active interface style based on app user settings
        static func getInterfaceStyle() -> UIUserInterfaceStyle {
            if let useSystemMode = UserDefaults.standard.object(forKey: self.useSystemMode) as? Bool {
                if useSystemMode {
                    // return device interface style that is currently affecting app
                    return UIScreen.main.traitCollection.userInterfaceStyle
                }
                else if let userInterfaceSetting = UserDefaults.standard.object(forKey: self.appearanceMode) as? String {
                    // return the custom user setting
                    if userInterfaceSetting == self.AppearanceModes.lightMode {
                        return .light
                    }
                    else {
                        return .dark
                    }
                }
            }
            
            // default to dark I guess
            return .dark
        }
        
        struct DefaultValue {
            // General
            static let localNotifications = false
            
            // Appearance
            static let useSystemMode = false
            static let appearanceMode = Settings.AppearanceModes.darkMode
            static let favoritesBadgeCount = true
            static let highlightDeals = true
        }
    }
    
    // game defaults when no info is pulled from API
    struct GameDefaults {
        static let priceRange = "Not available"
        static let esrb = "Not available"
        static let players = ""
        static let platform = "Not available"
        static let description = "Description unavailable"
        static let title = "Not available"
        
        static let availableNow = "Available now"
        static let releasePrefix = "Available "
        static let blankReleaseDateDefaultText = "Check later for availability"
        
        // example super meat boy: 2018-01-11T00:00:00.000Z
        static let dateInputFormat: String = "yyyy-MM-dd'T'HH:mm:ss.sss'Z'"
        // deprecated, but just in case, example: 2017-11-16T00:00:00.000-08:00
        static let dateInputFormat2: String = "yyyy-MM-dd'T'HH:mm:ss.sss-HH:mm"
        
        static let dateListingFormat: String = "MMM d, y"
        
        static let descriptionNumberOfLines: Int = 6
    }
    
    // cell colors
    struct GameCell {
        static let defaultDark: UIColor = .systemGray5
        static let defaultLight: UIColor = .systemGray6
        static let darkSale = UIColor(red: 58/255, green: 44/255, blue: 46/255, alpha: 1)
        static let lightSale = UIColor(red: 255/255, green: 229/255, blue: 234/255, alpha: 1)
    }
    
    // sorting options and mapping
    enum Sorting: String {
        case featured
        case releaseDate
        case titleAtoZ
        case titleZtoA
        case priceAscending
        case priceDescending
        
        var label: String {
            switch self {
            case .featured:
                return "Featured"
            case .releaseDate:
                return "Release Date"
            case .titleAtoZ:
                return "Title (A to Z)"
            case .titleZtoA:
                return "Title (Z to A)"
            case .priceAscending:
                return "Price (Low to High)"
            case .priceDescending:
                return "Price (High to Low)"
            }
        }
    }
    
    // static filter groups
    struct FilterGroup {
        static let general = "general"
        static let availability = "availability"
        static let genres = "genres"
        static let priceRange = "priceRange"
        static let franchises = "franchises"
        static let players = "players"
        static let esrbRating = "esrbRating"
    }
    
    // action sheet values for games table nav bar options button
    enum GameOptionsMenu: String {
        case favoritesAdd
        case favoritesRemove
        case eShopInternalBrowser
        case eShopExternalSafari
        case share
    }
    
    // action sheet for favorites menu options in the top right nav bar
    enum FavoritesOptionMenu: String {
        case edit
        case openWishlist
    }
    
    // favorites iamges for the navigation bar to swap between
    struct FavoritesNavBarImage {
        static let iconTrue = UIImage(named: "favoriteTrueNavBar")?.withRenderingMode(.alwaysOriginal)
        static let iconFalse = UIImage(named: "favoriteFalseNavBar")
    }
    
    // mapping for esrb image sets
    struct ESRB {
        struct fromAPI {
            static let e = "Everyone"
            static let e10 = "Everyone 10+"
            static let t = "Teen"
            static let m = "Mature"
        }
        
        struct imageString {
            static let e = "esrbEveryone"
            static let e10 = "esrbEveryone10"
            static let t = "esrbTeen"
            static let m = "esrbMature"
        }
    }
    
    // api for Nintendo Switch game updates
    struct GamesAPI {
        static let url = "REDACTED"
        static let resourceGames = "games/modified-after/"
        static let resourceNsuid = "games/nsuid/"
        static let queryKeyNsuid = "startNsuid"
        static let queryKeyLastModified = "startLastModified"
        
        // constant for the key storing the last update made timestamp
        struct UserDefaults {
            static let lastUpdateKey = "LastUpdateTimestamp"
            static let lastAPIUpdateTimestamp = "LastAPIUpdateTimestamp"
        }
    }
    
    // settings -> About links
    struct AboutLinks {
        // Author
        static let myGithubUrl: String = "https://github.com/bvanzile"
        static let myIgUrl: String = "https://www.instagram.com/bryan.vanzile/"
        
        // Contact
        static let contactEmail: String = "contactswitchhero@gmail.com"
        
        // Special Thanks
        static let alamofire: String = "https://github.com/Alamofire/Alamofire"
        static let sheet: String = "https://github.com/danielsaidi/Sheeeeeeeeet"
        static let nintendoSwitchEshop: String = "https://github.com/lmmfranco/nintendo-switch-eshop"
        static let kingfisher: String = "https://github.com/onevcat/Kingfisher"
        
        // rating link
        static let ratingsLink: String = "https://apps.apple.com/app/id979274575?action=write-review"
    }
    
    // error handling
    enum CustomError: Error {
        case failedToCreateRequest
        case failedToRetrieveGames
        case failedToGetLastEvaluatedKey
        case activeUpdateOngoing
    }
    
    // for turning an array of strings into a list with a separating character
    static func concatenateStringArray(_ array: [String], prefix: String = "", separator: String = ",", default defaultString: String = "") -> String {
        if array.count > 0 {
            var concatenatedString = prefix
            
            for (index, string) in array.enumerated() {
                if index > 0 {
                    concatenatedString = concatenatedString + separator + " " + string
                }
                else {
                    concatenatedString = concatenatedString + string
                }
            }
            
            return concatenatedString
        }
        else {
            return defaultString
        }
    }
}

// required to extend CustomError enum to provide localized descriptions
extension Config.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest:
            return NSLocalizedString("Unable to create the URLRequest object", comment: "")
            
        case .failedToRetrieveGames:
            return NSLocalizedString("Unable to instantiate games from API request", comment: "")
            
        case .failedToGetLastEvaluatedKey:
            return NSLocalizedString("Failed to insantiate LastEvaluatedKey items for next API call", comment: "")
            
        case .activeUpdateOngoing:
            return NSLocalizedString("Failed to start new update, previous update is still ongoing", comment: "")
        }
    }
}
