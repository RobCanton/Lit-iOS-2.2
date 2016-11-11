//
//  LocationService.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-06.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import ReSwift
import SwiftyJSON
import CoreLocation


class LocationService {

    static private let ref = FIRDatabase.database().reference().child("locations")
    
    static var shouldCalculateNearbyArea:Bool = true
    
    static func requestNearbyLocations(latitude:Double, longitude:Double) {
        
        let url = NSURL(string: "\(apiURL)/nearby/50/\(latitude)/\(longitude)")
        print("Requesting Nearby Locations: \(url!.absoluteString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                self.extractFeedFromJSON(data!)
            }
        }
        
        task.resume()
        
        if shouldCalculateNearbyArea {
            getCities({ _ in
                calculateNearbyArea(latitude, longitude: longitude)
            })
        }
    }
    
    static func extractFeedFromJSON(data:NSData) {
        var locationKeys = [String]()
        let json = JSON(data: data)
        print("EXTRACTING DATA")
        for (_,key):(String, JSON) in json["locations"] {
            
            locationKeys.append(key.stringValue)
        }
        
        let activeLocationKey = json["active_location"].stringValue
        
        print("ACTIVE LOCATION KEY: \(activeLocationKey)")
        
        getLocations(locationKeys, completionHandler:  { locations in
            
            if compareLocationsList(locations, listB: mainStore.state.locations) {
                print("Locations are equal. No action required")
            } else {
                print("Locations changed. Dispatch required")
                Listeners.stopListeningToLocations()
                mainStore.dispatch(LocationsRetrieved(locations: locations))
                Listeners.startListeningToLocations()
            }
            
            checkActiveLocation(activeLocationKey)
        })
    }
    
    static func checkActiveLocation(activeLocationKey:String) {

        let currentLocationKey = mainStore.state.userState.activeLocationKey
        
        if activeLocationKey != currentLocationKey {
            let uid = mainStore.state.userState.uid
            let locationRef = ref.child("visitors/\(activeLocationKey)/\(uid)")
            locationRef.setValue(true)
            let userRef = FirebaseService.ref.child("users/visits/\(uid)/\(activeLocationKey)")
            userRef.setValue(true)
            mainStore.dispatch(SetActiveLocation(locationKey: activeLocationKey))
        }
        
    }
    
    static func compareLocationsList(listA: [Location] , listB: [Location]) -> Bool {
        
        if listA.count != listB.count {
            return false
        }
        
        let sortedListA = listA.sort({ $0.getKey() > $1.getKey()})
        let sortedListB = listB.sort({ $0.getKey() > $1.getKey()})
        
        for i in 0 ..< sortedListA.count {
            if sortedListA[i].getKey() != sortedListB[i].getKey() {
                return false
            }
        }
        
        return true
    }
    
    
    static func getLocations(locationKeys:[String], completionHandler:(locations: [Location]) -> ()) {
        var locations = [Location]()
        var count = 0
        
        for key in locationKeys {
            getLocation(key, completionHandler: { location in
                if location != nil {
                    locations.append(location!)
                }
                count += 1
                
                if count >= locationKeys.count {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionHandler(locations: locations)
                    })
                }
            })
        }
    }
    
    static func getLocation(locationKey:String, completionHandler:(location:Location?)->()) {
        let locRef = FirebaseService.ref.child("locations/info/\(locationKey)")
        locRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var location:Location?
            if snapshot.exists() {
                let key         = snapshot.key
                let name        = snapshot.value!["name"] as! String
                let lat         = snapshot.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                let lon         = snapshot.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                let imageURL    = snapshot.value!["imageURL"] as! String
                let address     = snapshot.value!["address"] as! String
                
                location = Location(key: key, name: name, latitude: lat, longitude: lon, imageURL: imageURL, address: address)
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