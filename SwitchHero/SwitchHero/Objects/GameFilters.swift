//
//  GameFilters.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 5/27/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation

struct Filter {
    // dictionary filter for [filterable value: game count]
    var filter: [String: Int] = [:]
    var group: String
    
    // ordered keys to be displayed in the correct order
    var keys: [String] {
        get {
            if staticKeys == nil {
                return filter.keys.sorted()
            }
            else {
                if filter.count != staticKeys!.count {
                    print("Warning: Mismatch of static key counts (\(staticKeys!.count)) with filter count (\(filter.count))")
                }
                return staticKeys!
            }
        }
    }
    
    // for setting a static order for listing out the filter by key
    var staticKeys: [String]? {
        didSet {
            // set up the filter with the new static keys so they're always ready
            if staticKeys != nil {
                for key in staticKeys! {
                    filter[key] = 0
                }
            }
        }
    }
    
    init(named: String = "") {
        self.group = named
    }
    
    func zero() -> Filter {
        var copy = self
        
        for (key, _) in copy.filter {
            copy.filter[key] = 0
        }
        
        return copy
    }
}

// structure for storing active filters and amount of affected games
class GameFilters: NSCopying {
    var general = Filter(named: Config.FilterGroup.general)
    var availability = Filter(named: Config.FilterGroup.availability)
    var genres = Filter(named: Config.FilterGroup.genres)
    var priceRange = Filter(named: Config.FilterGroup.priceRange)
    var franchises = Filter(named: Config.FilterGroup.franchises)
    var players = Filter(named: Config.FilterGroup.players)
    var esrbRating = Filter(named: Config.FilterGroup.esrbRating)
    
    init() {
        // set up the static filter orders for price range and esrb rating (alphabetical doesn't work)
        priceRange.staticKeys = ["Free to start",
                                 "$0 - $4.99",
                                 "$5 - $9.99",
                                 "$10 - $19.99",
                                 "$20 - $39.99",
                                 "$40+"]
        
        esrbRating.staticKeys = ["Everyone",
                                 "Everyone 10+",
                                 "Teen",
                                 "Mature",
                                 "Rating Pending"]
    }
    
    
    // initialize an empty game filters object with all keys passed through
    init(from master: GameFilters) {
        // copy and zero out all filters
        self.general = master.general.zero()
        self.availability = master.availability.zero()
        self.genres = master.genres.zero()
        self.priceRange = master.priceRange.zero()
        self.franchises = master.franchises.zero()
        self.players = master.players.zero()
        self.esrbRating = master.esrbRating.zero()
    }
    
    // private init for copying
    private init(copyFrom master: GameFilters) {
        // copy all
        self.general = master.general
        self.availability = master.availability
        self.genres = master.genres
        self.priceRange = master.priceRange
        self.franchises = master.franchises
        self.players = master.players
        self.esrbRating = master.esrbRating
    }
    
    // populate filters with data from passed through game object
    func populateWithGame(_ game: GameListing) {
        // general filter
        for item in game.generalFilters {
            if general.filter[item] != nil {
                general.filter[item] = general.filter[item]! + 1
            }
            else {
                general.filter[item] = 1
            }
        }
        
        // availability filter
        for item in game.availability {
            if availability.filter[item] != nil {
                availability.filter[item] = availability.filter[item]! + 1
            }
            else {
                availability.filter[item] = 1
            }
        }
        
        // genres filter
        for item in game.genres {
            if genres.filter[item] != nil {
                genres.filter[item] = genres.filter[item]! + 1
            }
            else {
                genres.filter[item] = 1
            }
        }
        
        // price filter
        if game.hasPrice {
            if priceRange.filter[game.priceRange] != nil {
                priceRange.filter[game.priceRange] = priceRange.filter[game.priceRange]! + 1
            }
            else {
                priceRange.filter[game.priceRange] = 1
            }
        }
        // excludes games with no price from thus filter entirely
        
        // franchises filter
        for item in game.franchises {
            if franchises.filter[item] != nil {
                franchises.filter[item] = franchises.filter[item]! + 1
            }
            else {
                franchises.filter[item] = 1
            }
        }
        
        // players filter
        for item in game.playerFilters {
            if players.filter[item] != nil {
                players.filter[item] = players.filter[item]! + 1
            }
            else {
                players.filter[item] = 1
            }
        }
        
        // esrb rating filter
        if esrbRating.filter[game.esrbRating] != nil {
            esrbRating.filter[game.esrbRating] = esrbRating.filter[game.esrbRating]! + 1
        }
        else {
            esrbRating.filter[game.esrbRating] = 1
        }
    }
    
    // function for creating a copy of this object
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = GameFilters(copyFrom: self)
        return copy
    }
    
    // for testing
    func printOut() {
        print("General:")
        for index in general.keys {
            print("  \(index): \(general.filter[index]!)")
        }
        
        print("Availability:")
        for index in availability.keys {
            print("  \(index): \(availability.filter[index]!)")
        }
        
        print("Genres:")
        for index in genres.keys {
            print("  \(index): \(genres.filter[index]!)")
        }
        
        print("Price Range:")
        for index in priceRange.keys {
            print("  \(index): \(priceRange.filter[index]!)")
        }
        
        print("Franchises:")
        for index in franchises.keys {
            print("  \(index): \(franchises.filter[index]!)")
        }
        
        print("Players:")
        for index in players.keys {
            print("  \(index): \(players.filter[index]!)")
        }
        
        print("ESRB Rating:")
        for index in esrbRating.keys {
            print("  \(index): \(esrbRating.filter[index]!)")
        }
    }
}
