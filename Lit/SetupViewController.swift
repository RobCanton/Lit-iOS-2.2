//
//  SetupViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import UIKit
import ReSwift
import CoreLocation


class SetupViewController: UIViewController, StoreSubscriber, LocationServiceDelegate {


    let locationManager = CLLocationManager()
    
    
    @IBOutlet weak var enableLocationServicesButton: UIView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationService.sharedInstance.delegate = self
        retrieveCities()
    }
    
    func tracingLocation(currentLocation: CLLocation){
        LocationService.sharedInstance.stopUpdatingLocation()
        determineNearestCity(currentLocation)
    
    }
    func tracingLocationDidFailWithError(error: NSError) {
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func newState(state: AppState) {
        
    }
    
    var cities:[City]?
    var activeCity:City?
    var locations:[Location]?
    func retrieveCities() {
        print("retrieveCities")
        FIRDatabase.database().reference().child("cities")
            .observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                var cities = [City]()
                for city in snapshot.children {
                    let key = city.key!!
                    let name = city.value["name"] as! String
                    let lat = city.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                    let lon = city.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                    let coord = CLLocation(latitude: lat, longitude: lon)
                    let country = city.value["country"] as! String
                    let region = city.value["region"] as! String
                    
                    let city = City(key: key, name: name, coordinates: coord, country: country, region: region)
                    cities.append(city)
                }
                self.cities = cities
                LocationService.sharedInstance.startUpdatingLocation()
            })
    }
    
    func determineNearestCity(coordinate:CLLocation) {
        
        guard let cities = self.cities else {return}
        print("determineNearestCity")

        var minDistance = Double(MAXFLOAT)
        for city in cities {
            let coords = city.getCoordinates()
            let dist = coords.distanceFromLocation(coordinate)

            if dist < minDistance {
                minDistance = dist
                print("Active city: \(activeCity)")
                activeCity = city
            }
        }
        
        retrieveLocationsForCity()
        
    }
    
    func retrieveLocationsForCity() {
        
        print("retrieveLocationsForCity")
        let city = activeCity!.getKey()
        let ref = FIRDatabase.database().reference().child("locations/info")
        let query = ref.queryOrderedByChild("city").queryEqualToValue(city)
        print(city)
        query.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var locations = [Location]()
            for child in snapshot.children {
                let key = child.key!!
                let name = child.value["name"] as! String
                let lat = child.childSnapshotForPath("coordinates").value!["latitude"] as! Double
                let lon = child.childSnapshotForPath("coordinates").value!["longitude"] as! Double
                let coord = CLLocation(latitude: lat, longitude: lon)
                let imageURL = child.value["imageURL"] as! String
                let address = child.value["address"] as! String
                let description = child.value["description"] as! String
                let number = child.value["number"] as! String
                let website = child.value["website"] as! String
                
                let loc = Location(key: key, name: name, coordinates: coord, imageURL: imageURL, address: address, description: description, number: number, website: website)
                locations.append(loc)
            }
            self.locations = locations
            self.setupComplete()
        })
    }
    
    func setupComplete() {
        print("Setup complete")
        guard let cities     = self.cities else {return}
        guard let activeCity = self.activeCity else {return}
        guard let locations  = self.locations else {return}

        mainStore.dispatch(CitiesRetrieved(cities: cities))
        mainStore.dispatch(SetActiveCity(city: activeCity))
        mainStore.dispatch(LocationsRetrieved(locations: locations))
        
        Listeners.listenToLocations()
        Listeners.listenToFriends()
        Listeners.listenToFriendRequests()
        Listeners.listenToConversations()
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
