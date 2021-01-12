//
//  GameJSONStructure.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/29/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation

// partial game details used for the master games list
struct GameListing: Codable {
    let esrbRating: String
    let msrp: Double
    let lastModified: Int
    let releaseDateDisplay: String
    let franchises: [String]
    let boxart: String
    let availability: [String]
    let salePrice: Double
    let nsuid: Int
    let platform: String
    var playerFilters: [String]
    let generalFilters: [String]
    let priceRange: String
    let genres: [String]
    let featured: Bool
    let title: String
    
    // calculated properties not returned in JSON response
    let onSale: Bool
    let hasPrice: Bool
    
    // game structures can be initialized with Dynamodb formatted JSON decoded to DynameGameinfo struct
    init?(_ game: DynamoGameShortInfo) {
        // a game is invalid if it doesn't contain a nsuid, return init failure
        if let nsuidString = game.nsuid?.S {
            if let nsuidInt = Int(nsuidString) {
                self.nsuid = nsuidInt
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
        
        // start building the game details from the dynamodb json format
        self.esrbRating = unpackDynamoString(game.esrbRating, defaultString: Config.GameDefaults.esrb)
        // msrp below
        self.lastModified = unpackDynamoNumber(game.lastModified, defaultInt: 1)
        self.releaseDateDisplay = unpackDynamoString(game.releaseDateDisplay, defaultString: "")
        self.franchises = unpackDynamoList(game.franchises)
        self.boxart = unpackDynamoString(game.boxart, defaultString: "")
        self.availability = unpackDynamoList(game.availability)
        // salePrice below
        // nsuid above
        self.platform = unpackDynamoString(game.platform, defaultString: Config.GameDefaults.platform)
        self.playerFilters = unpackDynamoList(game.playerFilters)
        // generalFilters below
        // priceRange below
        self.genres = unpackDynamoList(game.genres)
        self.featured = unpackDynamoBool(game.featured, defaultBool: false)
        self.title = unpackDynamoString(game.title, defaultString: Config.GameDefaults.title)
        
        // unpack the general filters but add Featured as a filterable option, if true
        if self.featured {
            var tempGeneralFilters = unpackDynamoList(game.generalFilters)
            tempGeneralFilters.append("Featured")
            
            self.generalFilters = tempGeneralFilters
        }
        else {
            self.generalFilters = unpackDynamoList(game.generalFilters)
        }
        
        // check the weird sale price structure
        if let salePriceString = game.salePrice?.N {
            if let salePrice = Double(salePriceString) {
                self.salePrice = salePrice
                self.onSale = true
            }
            else {
                self.onSale = false
                self.salePrice = -1
            }
        }
        else {
            self.onSale = false
            self.salePrice = -1
        }
        
        // handle the msrp, which can be null in DynamoDB's weird structure
        if isNull(game.msrp) {
            self.hasPrice = false
            self.msrp = -1
        }
        else {
            self.hasPrice = true
            self.msrp = unpackDynamoDoubleOrNull(game.msrp, defaultDouble: -1)
        }
        
        // price range also can be null, but just need a simple default value if it fails
        self.priceRange = unpackDynamoStringOrNull(game.priceRange, defaultString: "N/A")
    }
    
    // init from a full GameDetails object
    init?(_ game: GameDetails) {
        // directly inherit property values
        self.esrbRating = game.esrbRating
        self.msrp = game.msrp
        self.lastModified = game.lastModified
        self.releaseDateDisplay = game.releaseDateDisplay
        self.franchises = game.franchises
        self.boxart = game.boxart
        self.availability = game.availability
        self.salePrice = game.salePrice
        self.nsuid = game.nsuid
        self.platform = game.platform
        self.playerFilters = game.playerFilters
        self.generalFilters = game.generalFilters
        self.priceRange = game.priceRange
        self.genres = game.genres
        self.featured = game.featured
        self.title = game.title
        self.onSale = game.onSale
        self.hasPrice = game.hasPrice
    }
}

// make object equatable so we can compare new GameDetails to saved from JSON
extension GameListing: Equatable {
    static func == (lhs: GameListing, rhs: GameListing) -> Bool {
        return lhs.esrbRating == rhs.esrbRating
            && lhs.msrp == rhs.msrp
            && lhs.lastModified == rhs.lastModified
            && lhs.releaseDateDisplay == rhs.releaseDateDisplay
            && lhs.franchises == rhs.franchises
            && lhs.boxart == rhs.boxart
            && lhs.availability == rhs.availability
            && lhs.salePrice == rhs.salePrice
            && lhs.nsuid == rhs.nsuid
            && lhs.platform == rhs.platform
            && lhs.playerFilters == rhs.playerFilters
            && lhs.generalFilters == rhs.generalFilters
            && lhs.priceRange == rhs.priceRange
            && lhs.genres == rhs.genres
            && lhs.featured == rhs.featured
            && lhs.title == rhs.title
            && lhs.onSale == rhs.onSale
            && lhs.hasPrice == rhs.hasPrice
    }
}

// full game details
struct GameDetails: Codable {
    let lastModified: Int
    let horizontalHeaderImage: String
    let franchises: [String]
    let url: String
    let boxart: String
    let supportedLanguages: String
    let availability: [String]
    let salePrice: Double
    let playModes: [String]
    let priceRange: String
    let gallery: [String]
    let featured: Bool
    let freeToStart: Bool
    let esrbRating: String
    let msrp: Double
    let slug: String
    let publishers: [String]
    let releaseDateDisplay: String
    let lowestPrice: Double
    let numOfPlayers: String
    let nsuid: Int
    let fileSize: String
    let platform: String
    var playerFilters: [String]
    let generalFilters: [String]
    let esrbDescriptors: [String]
    let howToShop: [String]
    let developers: [String]
    let description: String
    let genres: [String]
    let title: String
    
    // custom details, not from db
    let onSale: Bool
    let hasPrice: Bool
    
    // game structures can be initialized with Dynamodb formatted JSON decoded to DynameGameinfo struct
    init?(_ game: DynamoGameDetails) {
        // a game is invalid if it doesn't contain a nsuid, return init failure
        if let nsuidString = game.nsuid?.S {
            if let nsuidInt = Int(nsuidString) {
                self.nsuid = nsuidInt
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
        
        // start building the game details from the dynamodb json format
        self.lastModified = unpackDynamoNumber(game.lastModified, defaultInt: 1)
        self.horizontalHeaderImage = unpackDynamoString(game.horizontalHeaderImage, defaultString: "")
        self.franchises = unpackDynamoList(game.franchises)
        self.url = unpackDynamoString(game.url, defaultString: "")
        self.boxart = unpackDynamoString(game.boxart, defaultString: "")
        self.supportedLanguages = unpackDynamoString(game.supportedLanguages, defaultString: "")
        self.availability = unpackDynamoList(game.availability)
        // salePrice below
        self.playModes = unpackDynamoList(game.playModes)
        // priceRange below
        self.gallery = unpackDynamoList(game.gallery)
        self.featured = unpackDynamoBool(game.featured, defaultBool: false)
        self.freeToStart = unpackDynamoBool(game.freeToStart, defaultBool: false)
        self.esrbRating = unpackDynamoString(game.esrbRating, defaultString: Config.GameDefaults.esrb)
        // msrp below
        self.slug = unpackDynamoString(game.slug, defaultString: "")
        self.publishers = unpackDynamoList(game.publishers)
        self.releaseDateDisplay = unpackDynamoString(game.releaseDateDisplay, defaultString: "")
        self.lowestPrice = unpackDynamoDoubleOrNull(game.lowestPrice, defaultDouble: -1)
        self.numOfPlayers = unpackDynamoString(game.numOfPlayers, defaultString: Config.GameDefaults.players)
        // nsuid above
        self.fileSize = unpackDynamoString(game.fileSize, defaultString: "")
        self.platform = unpackDynamoString(game.platform, defaultString: Config.GameDefaults.platform)
        self.playerFilters = unpackDynamoList(game.playerFilters)
        // generalFilters below
        self.esrbDescriptors = unpackDynamoList(game.esrbDescriptors)
        self.howToShop = unpackDynamoList(game.howToShop)
        self.developers = unpackDynamoList(game.developers)
        self.description = unpackDynamoString(game.description, defaultString: Config.GameDefaults.description)
        self.genres = unpackDynamoList(game.genres)
        self.title = unpackDynamoString(game.title, defaultString: Config.GameDefaults.title)
        
        // unpack the general filters but add Featured as a filterable option, if true
        if self.featured {
            var tempGeneralFilters = unpackDynamoList(game.generalFilters)
            tempGeneralFilters.append("Featured")
            
            self.generalFilters = tempGeneralFilters
        }
        else {
            self.generalFilters = unpackDynamoList(game.generalFilters)
        }
        
        // check the weird sale price structure
        if let salePriceString = game.salePrice?.N {
            if let salePrice = Double(salePriceString) {
                self.salePrice = salePrice
                self.onSale = true
            }
            else {
                self.onSale = false
                self.salePrice = -1
            }
        }
        else {
            self.onSale = false
            self.salePrice = -1
        }
        
        // handle the msrp, which can be null in DynamoDB's weird structure
        if isNull(game.msrp) {
            self.hasPrice = false
            self.msrp = -1
        }
        else {
            self.hasPrice = true
            self.msrp = unpackDynamoDoubleOrNull(game.msrp, defaultDouble: -1)
        }
        
        // price range also can be null, but just need a simple default value if it fails
        self.priceRange = unpackDynamoStringOrNull(game.priceRange, defaultString: "N/A")
    }
}
