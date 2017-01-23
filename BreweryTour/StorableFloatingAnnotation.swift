//
//  StorableFloatingAnnotation.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/23/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

protocol StorableFloatingAnnotation {
    func getFloatingAnnotation() -> MKAnnotation?
    func setFloating(annotation: MKAnnotation)
}
