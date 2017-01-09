//
//  LocationService.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import CoreLocation
import Foundation


class LocationService {

    static private let locationsCache = NSCache()
    
    static private let ref = FIRDatabase.database().reference().child("locations")
    
    static var shouldCalculateNearbyArea:Bool = true
    
    static func requestNearbyLocations(latitude:Double, longitude:Double) {
        
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("api/requests/location_updates/\(uid)")
        ref.setValue([
                "lat": latitude,
                "lon": longitude,
                "rad": 150
            ])
        
    }
    
    static func handleLocationsResponse(locationKeys:[String:Double], active:String) {
//        if compareLocationsList(locationKeys) {
//            print("Locations are equal. No action required")
//        } else {
//            print("Locations changed. Dispatch required")
            getLocations(locationKeys, completionHandler:  { locations in
                Listeners.stopListeningToLocations()
                mainStore.dispatch(LocationsRetrieved(locations: locations))
                Listeners.startListeningToLocations()
                
                checkActiveLocation(active)
            })
//        }
    }
    
    
    static func checkActiveLocation(activeLocationKey:String) {

        let currentLocationKey = mainStore.state.userState.activeLocationKey
        
        if activeLocationKey != currentLocationKey {
            let uid = mainStore.state.userState.uid
//            let locationRef = ref.child("visitors/\(activeLocationKey)/\(uid)")
//            locationRef.setValue([".sv": "timestamp"])
//            let userRef = FirebaseService.ref.child("users/visits/\(uid)/\(activeLocationKey)")
//            userRef.setValue([".sv": "timestamp"])
            mainStore.dispatch(SetActiveLocation(locationKey: activeLocationKey))
        }
        
    }
    
    static func compareLocationsList(listA: [String]) -> Bool {
        let currentList = mainStore.state.locations
        if listA.count != currentList.count {
            return false
        }
        
        let sortedListA = listA.sort({ $0 > $1 })
        let sortedListB = currentList.sort({ $0.getKey() > $1.getKey()})
        
        for i in 0 ..< sortedListA.count {
            if sortedListA[i] != sortedListB[i].getKey() {
                return false
            }
        }
        
        return true
    }
    
    static func getLocations(locationDict:[String:Double], completionHandler:(locations: [Location]) -> ()) {
        var locations = [Location]()
        var count = 0
        
        for (key, dist) in locationDict {
            getLocation(key, completionHandler: { location in
                if location != nil {
                    location?.setDistance(dist)
                    locations.append(location!)
                }
                count += 1
                
                if count >= locationDict.count {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(locations: locations)
                    })
                }
            })
        }
    }
    
    static func getLocation(locationKey:String, completionHandler:(location:Location?)->()) {
        if let cachedData = locationsCache.objectForKey(locationKey) as? Location {
            return completionHandler(location: cachedData)
        }
        
        let locRef = FirebaseService.ref.child("locations/info/basic/\(locationKey)")
        locRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var location:Location?
            if snapshot.exists() {
                let key         = snapshot.key
                let name        = snapshot.value!["name"] as! String
                let lat         = snapshot.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                let lon         = snapshot.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                let imageURL    = snapshot.value!["imageURL"] as! String
                let address     = snapshot.value!["address"] as! String
                
                location = Location(key: key, name: name, latitude: lat, longitude: lon, imageURL: imageURL, address: address,
                    full_address: nil, phone: nil, email: nil, website: nil, desc: nil)
                locationsCache.setObject(location!, forKey: key)
            }
            completionHandler(location: location)
        })
    }
    
    static func getLocationDetails(location:Location, completionHandler: (location:Location)->()) {
        if location.full_address != nil && location.phone != nil
            && location.website != nil {
            completionHandler(location: location)
        }
        let ref = FirebaseService.ref.child("locations/info/details/\(location.getKey())")
        ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.exists() {
                location.full_address = snapshot.value!["full_address"] as? String
                location.phone        = snapshot.value!["phone"] as? String
                location.email        = snapshot.value!["email"] as? String
                location.website      = snapshot.value!["website"] as? String
                location.desc         = snapshot.value!["description"] as? String
                
                let key = location.getKey()
                locationsCache.removeObjectForKey(key)
                locationsCache.setObject(location, forKey: key)
            }
            completionHandler(location: location)
        })
    }
    
    static func getCities(completionHandler:(cities:[City])->()) {
        FIRDatabase.database().reference().child("cities")
            .observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                var cities = [City]()
                for city in snapshot.children {
                    let key = city.key!!
                    let name = city.value["name"] as! String
                    let lat = city.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                    let lon = city.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                    let country = city.value["country"] as! String
                    let region = city.value["region"] as! String
                    
                    let city = City(key: key, name: name, latitude: lat, longitude: lon, country: country, region: region)
                    cities.append(city)
                }
                mainStore.dispatch(CitiesRetrieved(cities: cities))
                completionHandler(cities: cities)
            })
    }
    
    static func calculateNearbyArea(latitude:Double, longitude:Double){
        shouldCalculateNearbyArea = false
        let coord = CLLocation(latitude: latitude, longitude: longitude)
        var minDistance = Double(MAXFLOAT)
        var nearestCity:City!
        let cities = mainStore.state.cities
        for city in cities {
            let cityCoords = city.getCoordinates()
            let distance = cityCoords.distanceFromLocation(coord)
            if distance < minDistance {
                minDistance = distance
                nearestCity = city
            }
        }

        let lastLocationString = nearestCity.getKey()
        let ref = FIRDatabase.database().reference().child("users/lastLocation/\(mainStore.state.userState.uid)")
        ref.setValue(lastLocationString)
    }

    
}