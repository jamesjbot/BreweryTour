//
//  ConvertToFullStateName.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/25/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

/// This structs allows us to convert abbreviated 2 character states names in to fully
/// qualified names.
struct ConvertToFullStateName {

    var dictionary: Dictionary = [
        	"AL":"ALABAMA",
        	"AK":"ALASKA",
        	"AZ":"ARIZONA",
        	"AR":"ARKANSAS",
        	"CA":"CALIFORNIA",
        	"CO":"COLORADO",
        	"CT":"CONNECTICUT",
        	"DE":"DELAWARE",
        	"FL":"FLORIDA",
        	"GA":"GEORGIA",
        	"HI":"HAWAII",
        	"ID":"IDAHO",
        	"IL":"ILLINOIS",
            "IN":"INDIANA",
        	"IA":"IOWA",
        	"KS":"KANSAS",
        	"KY":"KENTUCKY",
        	"LA":"LOUISIANA",
        	"ME":"MAINE",
        	"MD":"MARYLAND",
        	"MA":"MASSACHUSETTS",
        	"MI":"MICHIGAN",
        	"MN":"MINNESOTA",
        	"MS":"MISSISSIPPI",
        	"MO":"MISSOURI",
        	"MT":"MONTANA",
        	"NE":"NEBRASKA",
        	"NV":"NEVADA",
        	"NH":"NEW+HAMPSHIRE",
        	"NJ":"NEW+JERSEY",
        	"NM":"NEW+MEXICO",
        	"NY":"NEW+YORK",
        	"NC":"NORTH+CAROLINA",
        	"ND":"NORTH+DAKOTA",
        	"OH":"OHIO",
        	"OK":"OKLAHOMA",
            "OR":"OREGON",
        	"PA":"PENNSYLVANIA",
        	"RI":"RHODE+ISLAND",
        	"SC":"SOUTH+CAROLINA",
        	"SD":"SOUTH+DAKOTA",
        	"TN":"TENNESSEE",
        	"TX":"TEXAS",
        	"UT":"UTAH",
        	"VT":"VERMONT",
        	"VA":"VIRGINIA",
        	"WA":"WASHINGTON",
        	"WV":"WEST+VIRGINIA",
        	"WI":"WISCONSIN",
        	"WY":"WYOMING"
    ]

    /// Converts two character U.S. state name abbreviations to full names
    ///
    /// - parameters:
    ///     - fromAbbreviation: Two character state abbreviation
    ///
    /// - returns:
    ///     - A String containing the full state name with + instead of spaces.
    func fullname(fromAbbreviation state: String) -> String {
        return dictionary[state] ?? ""
    }
}
