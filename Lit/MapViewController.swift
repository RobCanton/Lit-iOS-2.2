//
//  MapViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var location:Location!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let regionRadius: CLLocationDistance = 750
        let coordinate = location.getCoordinates().coordinate
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.pitchEnabled = true
        
        mapView.setRegion(coordinateRegion, animated: true)
        let a = MapPin(coordinate: coordinate, title: location.getName(), subtitle: location.getAddress())
        mapView.addAnnotation(a)
    }
    
    
    func setLocation(_location:Location) {
        self.location = _location
        
        
    }
    
    
}

class MapPin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
