//
//  GameListingManager.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/29/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Alamofire

struct FavoritedGame: Codable {
    var nsuid: Int
}

class GameManager {
    // singleton usage/setup
    static let instance = GameManager()
    
    private init() {
        // load the favorited games from user defaults
        if let data = UserDefaults.standard.value(forKey: Config.SavedUserData.favorites) as? Data {
            // decode into struct array
            if let userFavorites = try? PropertyListDecoder().decode(Array<FavoritedGame>.self, from: data) {
                // pull out nsuids and update the favorited nsuids
                var nsuids = [Int]()
                
                for game in userFavorites {
                    nsuids.append(game.nsuid)
                }
                
                self.favoritedNsuids = nsuids
            }
            else {
                print("Failed to decode favorites from UserDefaults")
            }
        }
    }
    
    // is the app actively attempting to update?
    private var isUpdating: Bool = false
    
    // favorites tab bar item referenced so we can update the badge
    private var favoritesTabBarItem: UITabBarItem?
    
    // queue to make array manipulation thread safe
    private let dataQueue = DispatchQueue(label: "com.bvz.queue.game.data", attributes: .concurrent)
    
    // master list of games
    private var _gamesMaster: [Game] = [Game]()
    private var gamesMaster: [Game] {
        get {
            return dataQueue.sync {
                _gamesMaster
            }
        }
        set (newData) {
            dataQueue.async(flags: .barrier) {
                self._gamesMaster = newData
            }
        }
    }
    
    // filtered and sorted games for display in the Games tab
    private var _filteredSortedGames: [Game] = [Game]()
    private var filteredSortedGames: [Game] {
        get {
            return dataQueue.sync {
                _filteredSortedGames
            }
        }
        set (newData) {
            dataQueue.async(flags: .barrier) {
                self._filteredSortedGames = newData
            }
        }
    }
    
    // master list of filters
    private var gameFiltersMaster: GameFilters = GameFilters()
    
    // used for tracking filter status
    private var activeFilters: [String: [String]] = [:]
    private var gameFilters: GameFilters = GameFilters()
    private var savedFilteredGames: [Game] = [Game]()
    private var titleSearch: String?
    
    // used for tracking sorting status
    private var activeSorting: Config.Sorting = .featured
    
    // favorited nsuids that are kept up to date with UserDefaults, used for initializing games
    private var favoritedNsuids: [Int]?
    
    // user favorites that automatically updates the UserDefaults when changes are made
    private var userFavorites: [Game] = [Game]() {
        didSet {
            // check if badge updates are enabled
            self.updateTabBar()
            
            print("Saving favorites to UserDefaults")
            self.saveFavorites()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FavoritesLoaded"), object: nil)
        }
    }
    
    // get reference of the favorites tab bar item for changing badge number on favorites change
    func retrieveFavoritesTabBarItem(_ item: UITabBarItem?) {
        self.favoritesTabBarItem = item
    }
    
    // returns game from the filtered/sorted game array that corresponds to passed through index
    func getGameForRow(atIndex index: Int) -> Game? {
        var game: Game?
        if index >= 0 && index < self.filteredSortedGames.count {
            game = self.filteredSortedGames[index]
        }
        
        return game
    }
    
    // get the count of filtered/sorted games
    func gamesTabRowCount() -> Int? {
        var count: Int?
        count = self.filteredSortedGames.count
        
        return count
    }
    
    func getCurrentFilter() -> GameFilters? {
        return self.gameFilters.copy() as? GameFilters
    }
    
    // get the number of filters that are currently active
    func activeFilterCount() -> Int {
        // iterate through the current filter to get the count
        var count: Int = 0
        for (_, category) in self.activeFilters {
            for _ in category {
                count = count + 1
            }
        }
        
        return count
    }
    
    // massage down to list of filtered, sorted games based on the full game list and active filters/sort
    func updateFilterAndSortedGames(skipFilter: Bool = false) {
        var gameArray = [Game]()
        
        if skipFilter {
            gameArray = self.savedFilteredGames
        }
        else {
            gameArray = self.gamesMaster
            
            // apply the filters
            for (key, filters) in self.activeFilters {
                for filter in filters {
                    switch key {
                    case Config.FilterGroup.general:
                        gameArray = gameArray.filter { $0.listing.generalFilters.contains(filter) }
                        
                    case Config.FilterGroup.availability:
                        gameArray = gameArray.filter { $0.listing.availability.contains(filter) }
                        
                    case Config.FilterGroup.priceRange:
                        gameArray = gameArray.filter { $0.listing.priceRange == filter }
                        
                    case Config.FilterGroup.players:
                        gameArray = gameArray.filter { $0.listing.playerFilters.contains(filter) }
                        
                    case Config.FilterGroup.genres:
                        gameArray = gameArray.filter { $0.listing.genres.contains(filter) }
                        
                    case Config.FilterGroup.franchises:
                        gameArray = gameArray.filter { $0.listing.franchises.contains(filter) }
                        
                    case Config.FilterGroup.esrbRating:
                        gameArray = gameArray.filter { $0.listing.esrbRating == filter }
                        
                    default:
                        print("Invalid filter detected")
                        break
                    }
                }
            }
            
            // save this for the ability to skip re-filtering every call
            self.savedFilteredGames = gameArray
            self.gameFilters = self.buildGameFiltersCount(gameArray)
        }
                
        // filter out titles based on text search if one is active
        if let searchText = self.titleSearch {
            gameArray = gameArray.filter {
                $0.listing.title.range(of: searchText, options: .caseInsensitive) != nil
            }
        }

        // setup the sorting for the remaining games to be displayed
        switch self.activeSorting {
        case .featured:
            gameArray.sort(by: { $0.listing.featured && !$1.listing.featured })
        case .releaseDate:
            gameArray.sort(by: { $0.listing.releaseDateDisplay > $1.listing.releaseDateDisplay })
        case .titleAtoZ:
            gameArray.sort(by: { $0.listing.title < $1.listing.title })
        case .titleZtoA:
            gameArray.sort(by: { $0.listing.title > $1.listing.title })
        case .priceAscending:
            gameArray.sort(by: { $0.ascendingSortPrice < $1.ascendingSortPrice })
        case .priceDescending:
            gameArray.sort(by: { $0.descendingSortPrice > $1.descendingSortPrice })
        }
        
        self.filteredSortedGames = gameArray
    }
    
    // returns whether the sort type changed
    func setSort(to sortOption: Config.Sorting) -> Bool {
        if sortOption != self.activeSorting {
            self.activeSorting = sortOption
            
            self.updateFilterAndSortedGames(skipFilter: true)
            
            return true
        }
        
        return false
    }
    
    // get the currently active sorting type
    func getSort() -> Config.Sorting {
        return self.activeSorting
    }
    
    // activate or de-activate a filter from the action sheet
    func changeActiveFilter(group: String, key: String, selected: Bool) {
        if selected {
            if !isFilterActive(group: group, key: key) {
                if self.activeFilters[group] == nil {
                    self.activeFilters[group] = [key]
                }
                else {
                    self.activeFilters[group]!.append(key)
                }
            }
            else {
                print("Error: Filter was already active")
            }
        }
        else {
            if isFilterActive(group: group, key: key) {
                if self.activeFilters[group]!.count > 1 {
                    if let index = self.activeFilters[group]!.firstIndex(of: key) {
                        self.activeFilters[group]!.remove(at: index)
                    }
                }
                else {
                    self.activeFilters[group] = nil
                }
            }
            else {
                print("Error: Filter was already active")
            }
        }
        
        self.updateFilterAndSortedGames()
        print("Active filters: \(self.activeFilters)")
    }
    
    // removes all filters
    func clearActiveFilters() {
        self.activeFilters = [:]
        
        self.updateFilterAndSortedGames()
        print("Active filters: \(self.activeFilters)")
    }
    
    // return whether the passed through filter is active
    func isFilterActive(group: String, key: String) -> Bool {
        if activeFilters[group] != nil {
            if activeFilters[group]!.contains(key) {
                return true
            }
        }
        
        return false
    }
    
    // build the filter list from scratch
    func buildGameFiltersCount(_ games: [Game]) -> GameFilters {
        let newFilter = GameFilters(from: self.gameFiltersMaster)
        
        for game in games {
            newFilter.populateWithGame(game.listing)
        }
        
        return newFilter
    }
    
    func searchTitlesFor(_ searchText: String) {
        if searchText != self.titleSearch {
            if searchText.count > 0 {
                titleSearch = searchText
            }
            else {
                titleSearch = nil
            }
            
            self.updateFilterAndSortedGames(skipFilter: true)
        }
    }
    
    func favoritesCount() -> Int {
        return self.userFavorites.count
    }
    
    // used in games initializer to determine if the game is actively on the favorites list
    func isFavorited(_ nsuid: Int) -> Bool {
        // unwrap, should always be set since it gets set in init
        if let gameNsuids = self.favoritedNsuids {
            if gameNsuids.contains(nsuid) {
                return true
            }
            else {
                return false
            }
        }
        else {
            // shouldn't ever return false since the wishlist nsuids are loaded in the initializer
            return false
        }
    }
    
    // returns favorited game at the specified table index
    func getFavoritedGame(atIndex index: Int) -> Game? {
        var game: Game?
        if index >= 0 && index < self.userFavorites.count {
            game = self.userFavorites[index]
        }
        
        return game
    }
    
    // add the parameter game to the favorites list
    func addToFavorites(_ game: Game) -> Bool {
        self.userFavorites.append(game)
        
        return true
    }
    
    // remove the parameter game from the favorites list
    func removeFromFavorites(_ game: Game) -> Bool {
        self.userFavorites.removeAll{ $0 == game }
        
        return true
    }
    
    // remove the game at the specified index from the favorites list
    func removeFromFavorites(atIndex index: Int) -> Bool {
        if index < self.userFavorites.count {
            let _ = self.userFavorites.remove(at: index)
        }
        
        return true
    }
    
    // re-arrange the order of 2 games at specified indeces in the favorites list
    func moveFavoritedGames(sourceIndex: Int, destinationIndex: Int) {
        let movingGame = self.userFavorites[sourceIndex]
        
        // manipulate a copy so we only call the didSet save once
        var newFavorites = self.userFavorites
        newFavorites.remove(at: sourceIndex)
        newFavorites.insert(movingGame, at: destinationIndex)
        
        self.userFavorites = newFavorites
    }
    
    // populate the favorited games array when the master games list is loaded or updated
    func updateFavorites() {
        print("Attempting to populate the favorited games")
        var newFavorites: [Game] = [Game]()
        
        if let nsuids = self.favoritedNsuids {
            for nsuid in nsuids {
                if let game = self.gamesMaster.first(where: { $0.listing.nsuid == nsuid }) {
                    newFavorites.append(game)
                }
                else {
                    print("ERROR: Could not find a valid game with nsuid \(nsuid)")
                }
            }
        }

        print("Favorited games array populated with \(newFavorites.count) games")
        self.userFavorites = newFavorites
    }
    
    // transform the current favorited games array and save to UserDefaults
    private func saveFavorites() {
        // generate a new array of favorited games to overwrite saved array in UserDefaults
        var favoritedGames = [FavoritedGame]()
        var nsuids = [Int]()
        
        // fill in favorite games array
        for game in self.userFavorites {
            let favoritedGame = FavoritedGame(nsuid: game.listing.nsuid)
            favoritedGames.append(favoritedGame)
            nsuids.append(game.listing.nsuid)
        }
        
        // update the nsuid array
        self.favoritedNsuids = nsuids
        
        print("Saving \(favoritedGames.count) games to favorites")
        
        // attempt to encode and save the favorited games to UserDefaults
        let defaults = UserDefaults.standard
        if let encodedFavorites = try? PropertyListEncoder().encode(favoritedGames) {
            defaults.set(encodedFavorites, forKey: Config.SavedUserData.favorites)
        }
        else {
            print("Failed to encode favorited games and did not save to UserDefaults")
        }
    }
    
    // updates the badge for the Favorites icon on the tab bar
    func updateTabBar() {
        var allowBadge: Bool
        print("Updating tab bar")
        
        if let userSetting = UserDefaults.standard.object(forKey: Config.Settings.favoritesBadgeCount) as? Bool {
            allowBadge = userSetting
            print("Retrieved user setting: \(allowBadge)")
        }
        else {
            // set to default if this value was never set
            UserDefaults.standard.set(Config.Settings.DefaultValue.favoritesBadgeCount, forKey: Config.Settings.favoritesBadgeCount)
            allowBadge = Config.Settings.DefaultValue.favoritesBadgeCount
            print("User setting not found: defaulting to \(allowBadge)")
        }
        
        if allowBadge {
            // update the badge when this gets changed
            var count = 0
            for game in userFavorites {
                if game.listing.onSale { count += 1 }
            }
            
            if count == 0 {
                self.favoritesTabBarItem?.badgeValue = nil
            }
            else {
                self.favoritesTabBarItem?.badgeValue = String(count)
            }
        }
        else {
            self.favoritesTabBarItem?.badgeValue = nil
        }
    }
    
    func saveGamesJSONFile() -> Bool {
        let fm = FileManager.default
        let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let url = urls.first {
            do {
                var fileURL = url.appendingPathComponent(Config.localJsonFilename)
                fileURL = fileURL.appendingPathExtension("json")
                
                print("Saving games JSON to \(fileURL)")
                
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(self.getAllGameListings())
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    print("Failed to convert game details to JSON string")
                    return false
                }
                
                try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("File saved successfully")
            }
            catch {
                print("Error saving file: \(error)")
                return false
            }
            
            // return true on successful save
            return true
        }
        
        return false
    }
    
    // refresh the games listing with data from the file
    func readGamesFile() -> Bool {
        if !self.isUpdating {
            self.isUpdating = true
            
            let fm = FileManager.default
            let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let url = urls.first {
                var fileURL = url.appendingPathComponent(Config.localJsonFilename)
                fileURL = fileURL.appendingPathExtension("json")
                
                print("Attempting to read the games.json file @\(fileURL)")
                
                do {
                    try fm.createDirectory(at: url, withIntermediateDirectories: true)
                    
                    let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                    let decoder = JSONDecoder()
                    let model = try decoder.decode([GameListing].self, from: data)
                
                    var gameRefresh = [Game]()
                    let newFilter = GameFilters()
                    
                    for gameListing in model {
                        if let newGame = Game(game: gameListing) {
                            gameRefresh.append(newGame)
                            newFilter.populateWithGame(newGame.listing)
                        }
                    }
                    
                    print("Read \(gameRefresh.count) games from the file")
                    
                    self.gamesMaster = gameRefresh
                    self.gameFiltersMaster = newFilter
                    
                    self.updateFilterAndSortedGames()
                    self.updateFavorites()
                }
                catch {
                    print("Error reading games from json file: \(error)")
                    
                    self.isUpdating = false
                    return false
                }
                
                self.isUpdating = false
                return true
            }
            else {
                print("Error: Failed to retrieve Application Support Directory path")
            }
            
            self.isUpdating = false
        }
        
        return false
    }
    
    // for retrieving games and game updates from DynamoDB API call
    func retrieveGameUpdates(fullRefresh: Bool = false, completion: @escaping (_ success: Bool, _ error: Error?, _ newGames: Int?) -> Void) {
        // make sure no double calls are going on
        if self.isUpdating {
            completion(false, Config.CustomError.activeUpdateOngoing, nil)
        }
        else {
            // begin updating games
            self.isUpdating = true
            
            // get the update param for the url call
            var update: Int = 0
            var refreshGames: Bool = fullRefresh
            
            // get the most recent timestamp for game updates, located in User Defaults
            if !refreshGames {
                // returns 0 if not set, which will still be used in API call for a full update
                update = UserDefaults.standard.integer(forKey: Config.GamesAPI.UserDefaults.lastUpdateKey)
                
                // if update isn't set, force a full refresh of the games that come back from the API call
                if update == 0 {
                    refreshGames = true
                }
            }
            
            // build the url
            guard let urlComponents = URLComponents(string: Config.GamesAPI.url + Config.GamesAPI.resourceGames + String(update)) else {
                print("Failed to create URL for API update")
                self.isUpdating = false
                completion(false, Config.CustomError.failedToCreateRequest, nil)
                return
            }
            
            print("Preparing to request to \(urlComponents.url != nil ? urlComponents.url!.absoluteString : "nil")")
        
            // make the API request
            self.makeAPIRequest(urlComponents) { (success, error, games) in
                // do something with the games that came back
                if success {
                    if let newGames = games {
                        if refreshGames {
                            // build the master filters list
                            let newMasterFilter = self.buildGameFiltersCount(newGames)
                            let latestTimeStamp = newGames.max(by: {$0.listing.lastModified < $1.listing.lastModified})?.listing.lastModified
                            
                            // full refresh means overwrite the master games list
                            self.gamesMaster = newGames
                            self.gameFiltersMaster = newMasterFilter
                            self.updateFilterAndSortedGames()
                            self.updateFavorites()
                            
                            print("Update successful, retrieved \(newGames.count)")
                            
                            // update user defaults with the last time an update was made
                            if latestTimeStamp != nil {
                                self.updateUserDefaults(latestTimeStamp!)
                            }
                            else {
                                print("UserDefaults for last update not changed due to nil found in lastModified mapping")
                            }
                            self.isUpdating = false
                            completion(true, nil, newGames.count)
                        }
                        else {
                            print("Update successful, retrieved \(newGames.count)")
                            let latestTimeStamp = newGames.max(by: {$0.listing.lastModified < $1.listing.lastModified})?.listing.lastModified
                        
                            if newGames.count > 0 {
                                // transform to dictionary and update by key = nsuid
                                var gamesDict = Dictionary(uniqueKeysWithValues: self.gamesMaster.lazy.map{ ($0.listing.nsuid, $0) })
                                
                                // iterate and update temp dict
                                for game in newGames {
                                    gamesDict[game.listing.nsuid] = game
                                    print("Updating \(game.listing.title)")
                                }
                                
                                // transform back to master games array
                                let allGames = Array(gamesDict.values.map { $0 })
                                
                                let newFilter = self.buildGameFiltersCount(allGames)
                                
                                // rebuild master games/filter and current game list w/ active sort/filters
                                self.gamesMaster = allGames
                                self.gameFiltersMaster = newFilter
                                self.updateFilterAndSortedGames()
                                self.updateFavorites()
                                                
                                // update userdefaults with the timestamp for this completed update
                                if latestTimeStamp != nil {
                                    self.updateUserDefaults(latestTimeStamp!)
                                }
                                else {
                                    print("UserDefaults for last update not changed due to nil found in lastModified mapping")
                                }
                                
                                self.isUpdating = false
                                completion(true, nil, newGames.count)
                            }
                            else {
                                print("No game changes required")
                                self.isUpdating = false
                                completion(true, nil, 0)
                            }
                        }
                    }
                    else {
                        self.isUpdating = false
                        completion(false, Config.CustomError.failedToRetrieveGames, nil)
                    }
                }
                else {
                    self.isUpdating = false
                    completion(false, error, nil)
                }
            }
        }
    }
    
    // make api request for games based on the passed in url
    func makeAPIRequest(_ urlComponents: URLComponents, completion: @escaping (_ success: Bool, _ error: Error?, _ games: [Game]?) -> Void) {
        // unwrap the passed in url components
        guard let url = urlComponents.url else {
            completion(false, Config.CustomError.failedToCreateRequest, nil)
            return
        }
        
        // make the API call with the passed through url and rest manager object (that may contain query parameters)
        AF.request(url, method: .get).response(queue: DispatchQueue.global(qos: .background)) { (response) in
            if let error = response.error {
                completion(false, error, nil)
            }
            
            // unpack data to see if the rest call worked or came back with an error
            guard let data = response.data else {
                // handle the error, if it was passed
                print("Data not set from REST API response")
                if let error = response.error {
                    print(error)
                }
                
                // return as failed call
                completion(false, response.error, nil)
                return
            }
            
            print("Response received, parsing")

            // transform the data into Game objects
            do {
                // parse as Dynamodb JSON to DynamoGameData structure
                let decoder = JSONDecoder()
                let gameData = try decoder.decode(DynamoGameUpdateData.self, from: data)

                // initialize the acquired games into Game objects
                if let gamesFromApi = gameData.Items {
                    var newGames = [Game]()
                    
                    // instantiate a list of games
                    for game in gamesFromApi {
                        if let validGame = Game(game: game) {
                            newGames.append(validGame)
                        }
                        else {
                            print("Error: Could not initialize game from API (Init? returned nil)")
                        }
                    }

                    print("Received \(newGames.count) games from the Games API")
                    
                    // now check if the results are complete
                    if let lastEvaluatedKey = gameData.LastEvaluatedKey {
                        // if LastEvaluatedKey is valid, start working on a new url call with query for LastEvaluatedKey
                        if let nsuid = lastEvaluatedKey.nsuid?.S, let lastModified = lastEvaluatedKey.lastModified?.N {
                            // build the query parameters to continue retrieving game
                            let nsuidQuery = URLQueryItem(name: Config.GamesAPI.queryKeyNsuid, value: nsuid)
                            let lastModifiedQuery = URLQueryItem(name: Config.GamesAPI.queryKeyLastModified, value: lastModified)
                            
                            var newUrlComponents = urlComponents
                            newUrlComponents.queryItems = [nsuidQuery, lastModifiedQuery]

                            print("Preparing to request to \(newUrlComponents.url != nil ? newUrlComponents.url!.absoluteString : "nil")")
                            
                            self.makeAPIRequest(newUrlComponents) { (success, error, games) in
                                if success {
                                    // combine results to pass back through to the calling function
                                    if let incomingGames = games {
                                        newGames = newGames + incomingGames
                                        completion(true, nil, newGames)
                                    }
                                    else {
                                        completion(false, Config.CustomError.failedToRetrieveGames, nil)
                                    }
                                }
                                else {
                                    completion(false, error, nil)
                                }
                            }
                        }
                        else {
                            // Failed to insantiate LastEvaluatedKey items for next API call
                            completion(false, Config.CustomError.failedToGetLastEvaluatedKey, nil)
                        }
                    }
                    else {
                        print("No further API calls required")
                        completion(true, nil, newGames)
                    }
                }
                else {
                    completion(false, Config.CustomError.failedToRetrieveGames, nil)
                }
            } catch let parseError {
                print("JSON Error: \(parseError)")
                completion(false, response.error, nil)
            }
        }
    }
    
    // function called when API game update is completed to track for next one
    func updateUserDefaults(_ latestTimestamp: Int) {
        // grab the uessr defaults
        let defaults = UserDefaults.standard
        
        // set the new value for the most recent lastModified that came from the API update
        defaults.set(latestTimestamp, forKey: Config.GamesAPI.UserDefaults.lastUpdateKey)
        
        // set the new value for the last time an API update was made
        let now = Date().unixTimestampMS
        defaults.set(now, forKey: Config.GamesAPI.UserDefaults.lastAPIUpdateTimestamp)
        
        print("UserDefaults for last update set to \(latestTimestamp) and call was made at \(now)")
    }
    
    // deprecated
//    func gamesApiUpdate(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
//        guard let url = URL(string: (Config.API.url + Config.API.games)) else { return }
//
//        rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
//            // unpack data to see if the rest call worked or came back with an error
//            guard let data = results.data else {
//                // handle the error, if it was passed
//                print("Data not set from REST API response")
//                if let error = results.error {
//                    print(error)
//                }
//
//                completion(false, results.error)
//                return
//            }
//
//            print("Response received, parsing")
//
//            // transform the data into Game objects
//            do {
//                // parse as Dynamodb JSON to DynamoGameData structure
//                let decoder = JSONDecoder()
//                let gameData = try decoder.decode(DynamoGameData.self, from: data)
//
//                // initialize the acquired games into Game objects
//                if let gamesFromApi = gameData.Items {
//                    var newGames = [Game]()
//                    let newFilter = GameFilters()
//
//                    for game in gamesFromApi {
//                        if let validGame = Game(game: game) {
//                            newGames.append(validGame)
//                            newFilter.populateWithGame(validGame.listing)
//                        }
//                        else {
//                            print("Error: Could not initialize game from API (Init? returned nil)")
//                        }
//                    }
//
//                    print("Received \(newGames.count) games from the Games API")
//
//                    // TEMP: overwrite the games for now
//                    self.queue.sync {
//                        self.gamesMaster = newGames
//                        self.gameFiltersMaster = newFilter
//
//                        self.updateFilterAndSortedGames()
//                        self.gameFiltersMaster.printOut()
//
//                        completion(true, nil)
//                    }
//                }
//            } catch let parseError {
//                print("JSON Error: \(parseError)")
//                completion(false, results.error)
//            }
//        }
//    }

    // basic functions
    //
    func getAllGames() -> [Game] {
        return self.gamesMaster
    }
    
    func getAllGameListings() -> [GameListing] {
        var gameDetails = [GameListing]()
        for game in self.gamesMaster {
            gameDetails.append(game.listing)
        }
        
        return gameDetails
    }
    
    func add(_ game: Game) {
        self.gamesMaster.append(game)
    }

    func remove(_ game: Game) {
        self.gamesMaster.removeAll { $0.listing.nsuid == game.listing.nsuid }
    }
    
    func isEmpty() -> Bool {
        return self.gamesMaster.count == 0 ? true : false
    }
    
    func count() -> Int {
        return self.gamesMaster.count
    }
    
    // obsolete, but saved for dispatch group re-use
//    func populateVisibleBoxArt(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
//        // for making these API calls asynchronously
//        let dispatchGroup = DispatchGroup()
//
//        // track some stats, why not
//        var downloaded = 0
//        let cache = 0
//        var skipped = 0
//        var issues = 0
//
//        // iterate through the games visible in the games table controller and attempt to populate the box art
//        for game in self.visibleGames {
//            // skip over games that already have their box art populated
//            if game.boxArtImage == nil {
//                if let url = game.getBoxArtUrl() {
//                    // begin first dispatched async API call attempt
//                    dispatchGroup.enter()
//
//                    rest.makeRequest(toURL: url, withHttpMethod: .get) { (results) in
//                        // unpack data to see if the rest call worked or came back with an error
//                        guard let data = results.data else {
//                            print("Invalid data returned from API call @\(url)")
//
//                            // handle the error, if it was passed
//                            if let error = results.error {
//                                print(error)
//                            }
//
//                            issues += 1
//                            dispatchGroup.leave()
//                            return
//                        }
//
//                        if let image = UIImage(data: data) {
//                            game.boxArtImage = image
//                            downloaded += 1
//
//                            //self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
//                        }
//                        else {
//                            print("Could not resolve response as UIImage")
//                            issues += 1
//                        }
//
//                        dispatchGroup.leave()
//                    }
//                }
//                else {
//                    issues += 1
//                    print("Invalid URL: \(Config.nintendoUrl + game.details.boxArt)")
//                }
//            }
//            else {
//                print("Image already available")
//                skipped += 1
//            }
//        }
//
//        dispatchGroup.notify(queue: .main, execute: {
//            print("Box art calls completed with \(downloaded) successes, \(cache) from cache, \(issues) issues, and \(skipped) skipped")
//            completion(true, nil)
//        })
//    }
}
