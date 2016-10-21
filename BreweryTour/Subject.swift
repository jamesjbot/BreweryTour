//
//  Subject.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/21/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import UIKit

protocol Subject {
    func registerObserver(view: Observer)
}
