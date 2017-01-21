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
    
    static func handleLocationsResponse(locationKeys:[String:Double]) {
        getLocations(locationKeys, completionHandler:  { locations in
            Listeners.stopListeningToLocations()
            mainStore.dispatch(LocationsRetrieved(locations: locations))
            Listeners.startListeningToLocations()
        })
    }
    
    static func checkActiveLocation(activeLocationKey:String) {

        let currentLocationKey = mainStore.state.userState.activeLocationKey
        
        if activeLocationKey != currentLocationKey {
            let uid = mainStore.state.userState.uid
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
                     phone: nil, email: nil, website: nil, desc: nil)
                locationsCache.setObject(location!, forKey: key)
            }
            completionHandler(location: location)
        })
    }
    
    static func getLocationDetails(location:Location, completionHandler: (location:Location)->()) {
        if location.phone != nil && location.website != nil {
            completionHandler(location: location)
        }
        let ref = FirebaseService.ref.child("locations/info/details/\(location.getKey())")
        ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.exists() {
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
}