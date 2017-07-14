//
//  ParserProtocol.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

protocol ParserProtocol {
    func parse(response : NSDictionary,
               querySpecificID : String?,
               completion: (( (_ success :  Bool, _ msg: String?) -> Void )?) )
}
