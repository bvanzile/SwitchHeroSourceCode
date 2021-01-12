//
//  GameStructures.swift
//  SwitchHero
//
//  Created by Bryan Van Zile on 4/22/20.
//  Copyright © 2020 Bryan Van Zile. All rights reserved.
//


//Sample JSON format from AWS DynamoDB and API Gateway:
//
//{
//    "lastModified": {
//        "N": "1587513742299"
//    },
//    "characters": {
//        "L": [
//            {
//                "S": "Mario"
//            },
//            {
//                "S": "Mii"
//            }
//        ]
//    },
//    "url": {
//        "S": "/games/detail/super-mario-maker-2-switch"
//    },
//    { ...
//

import Foundation

// structure for the JSON return type from the games update API
struct DynamoGameUpdateData: Codable {
    var Count: Int
    var ScannedCount: Int
    var LastEvaluatedKey: DynamoLastEvaluatedKey?
    var Items: [DynamoGameShortInfo]?
}

struct DynamoLastEvaluatedKey: Codable {
    var nsuid: DynamoString?
    var lastModified: DynamoNumber?
}

struct DynamoGameShortInfo: Codable {
    var esrbRating: DynamoString?
    var msrp: DynamoDoubleOrNull?
    var lastModified: DynamoNumber?
    var releaseDateDisplay: DynamoString?
    var franchises: DynamoList?
    var boxart: DynamoString?
    var availability: DynamoList?
    var salePrice: DynamoDoubleOrNull?
    var nsuid: DynamoString?
    var platform: DynamoString?
    var playerFilters: DynamoList?
    var generalFilters: DynamoList?
    var priceRange: DynamoStringOrNull?
    var genres: DynamoList?
    var featured: DynamoBool?
    var title: DynamoString?
}

// second structure for reading games API response for a single game
struct DynamoGameDetailsData: Codable {
    var Count: Int
    var ScannedCount: Int
    var Items: [DynamoGameDetails]?
}

struct DynamoGameDetails: Codable {
    var lastModified: DynamoNumber?
    var horizontalHeaderImage: DynamoString?
    var franchises: DynamoList?
    var url: DynamoString?
    var boxart: DynamoString?
    var supportedLanguages: DynamoString?
    var availability: DynamoList?
    var salePrice: DynamoDoubleOrNull?
    var playModes: DynamoList?
    var priceRange: DynamoStringOrNull?
    var gallery: DynamoList?
    var featured: DynamoBool?
    var freeToStart: DynamoBool?
    var esrbRating: DynamoString?
    var msrp: DynamoDoubleOrNull?
    var slug: DynamoString?
    var publishers: DynamoList?
    var releaseDateDisplay: DynamoString?
    var lowestPrice: DynamoDoubleOrNull?
    var numOfPlayers: DynamoString?
    var nsuid: DynamoString?
    var fileSize: DynamoString?
    var platform: DynamoString?
    var playerFilters: DynamoList?
    var generalFilters: DynamoList?
    var esrbDescriptors: DynamoList?
    var howToShop: DynamoList?
    var developers: DynamoList?
    var description: DynamoString?
    var genres: DynamoList?
    var title: DynamoString?
}

// structures representing the weird JSON formating that comes out of DynamoDB
struct DynamoDoubleOrNull: Codable {
    var NULL: Bool?
    var N: String?
}

struct DynamoStringOrNull: Codable {
    var NULL: Bool?
    var S: String?
}

struct DynamoList: Codable {
    var L: [DynamoString]?
}

struct DynamoString: Codable {
    var S: String?
}

struct DynamoNumber: Codable {
    var N: String?
}

struct DynamoBool: Codable {
    var BOOL: Bool?
}

// for use when unpacking game JSON into GameDetail objects
func isNull(_ potentialDouble: DynamoDoubleOrNull?) -> Bool {
    // unwrap
    if let dDouble = potentialDouble {
        // check if the NULL attribute is set to true
        if dDouble.NULL == true {
            return true
        }
    }
    
    return false
}

func isNull(_ potentialString: DynamoStringOrNull?) -> Bool {
    // unwrap
    if let dString = potentialString {
        // check if the NULL attribute is set to true
        if dString.NULL == true {
            return true
        }
    }
    
    return false
}

func unpackDynamoDoubleOrNull(_ dynamoDouble: DynamoDoubleOrNull?, defaultDouble: Double) -> Double {
    // unwrap all the way
    if let dDouble = dynamoDouble {
        if let num = dDouble.N {
            if let double = Double(num) {
                return double
            }
            else {
                print("Invalid conversion from String to Double: \(num)")
            }
        }
    }
    
    return defaultDouble
}

func unpackDynamoStringOrNull(_ dynamoString: DynamoStringOrNull?, defaultString: String) -> String {
    // unwrap all the way
    if let dString = dynamoString {
        if let s = dString.S {
            return s
        }
    }
    
    return defaultString
}

func unpackDynamoList(_ list: DynamoList?) -> [String] {
    // unpack the dynamo list
    if let dList = list?.L {
        // pull together an array of simple strings from the messed up dynamo json format structure
        if(dList.count > 0) {
            var stringArray = [String]()
            
            for dString in dList {
                if let str = dString.S {
                    stringArray.append(str)
                }
            }
            
            return stringArray
        }
    }
    
    return [String]()
}

func unpackDynamoString(_ dynamoString: DynamoString?, defaultString: String) -> String {
    if let dString = dynamoString?.S {
        return dString
    }
    
    return defaultString
}

func unpackDynamoNumber(_ dynamoNumber: DynamoNumber?, defaultInt: Int) -> Int {
    if let dNumber = dynamoNumber?.N {
        if let integer = Int(dNumber) {
            return integer
        }
        else {
            print("Invalid conversion from String to Int: \(dNumber)")
        }
    }
    
    return defaultInt
}

func unpackDynamoNumber(_ dynamoNumber: DynamoNumber?, defaultDouble: Double) -> Double {
    if let dNumber = dynamoNumber?.N {
        if let double = Double(dNumber) {
            return double
        }
        else {
            print("Invalid conversion from String to Double: \(dNumber)")
        }
    }
    
    return defaultDouble
}

func unpackDynamoBool(_ dynamoBool: DynamoBool?, defaultBool: Bool) -> Bool {
    if let dBool = dynamoBool?.BOOL {
        return dBool
    }
    
    return defaultBool
}
