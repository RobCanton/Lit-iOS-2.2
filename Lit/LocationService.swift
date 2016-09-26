////
////  LocationService.swift
////  Lit
////
////  Created by Robert Canton on 2016-08-17.
////  Copyright © 2016 Robert Canton. All rights reserved.
////
//
//import CoreLocation
//import Foundation
//import ReSwift
//
//class LocationService: NSObject, CLLocationManagerDelegate {
//    
//    private let locationManager = CLLocationManager()
//    
//    private var userLocation:CLLocation?
//    
//    
//    func initiateLocationUpdater() {
//        locationManager.delegate = self
//        locationManager.requestAlwaysAuthorization()
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
//    }
//    
//    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: { (placemarks, error) ->
//            Void in
//            
//            if error != nil {
//                //print("Error: " + error!.localizedDescription)
//                return
//            }
//            if placemarks?.count > 0 {
//                let pm = placemarks![0] as CLPlacemark
//                self.checkCurrentLocation(pm)
//            }
//        })
//    }
//    
//    private func checkCurrentLocation(placemark: CLPlacemark) {
//        let latitude =  (placemark.location?.coordinate.latitude)!
//        let longitude = (placemark.location?.coordinate.longitude)!
//        let coordinate:CLLocation = CLLocation(latitude: latitude, longitude: longitude)
//        var minDistance = Double(MAXFLOAT)
//        let locations = mainStore.state.locations
//        var nearestLocationKey:String?
//        if locations.count != 0 {
//            for location in locations {
//                let distance = coordinate.distanceFromLocation(location.getCoordinates())
//                
//                if distance < minDistance {
//                    minDistance = distance
//                    nearestLocationKey = location.getKey()
//                }
//            }
//            if let _ = nearestLocationKey {
//                if nearestLocationKey! != mainStore.state.userLocationState.activeLocationKey {
//                    mainStore.dispatch(SetUserLocation(activeLocationKey: nearestLocationKey!))
//                }
//            }
//            
//        }
//    }
//    
//    /* GETTERS */
//    
//    func getUserLocation() -> CLLocation? {
//        return userLocation
//    }
//    
//    
//    
//    
// 
// 
//}
