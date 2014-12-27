//
//  CustomMKAnnotation.swift
//  DropChat
//
//  Created by Eric Smith on 12/13/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit
import MapKit

class CustomMKAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var markerData: NSDictionary
    
    init(coordinate: CLLocationCoordinate2D, markerData: NSDictionary) {
        self.markerData = markerData
        self.coordinate = coordinate
    }
}
