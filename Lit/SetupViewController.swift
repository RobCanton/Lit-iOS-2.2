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
import IngeoSDK


class SetupViewController: UIViewController,IGLocationManagerDelegate, StoreSubscriber {


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

        startSetup()
        
        // Do any additional setup after loading the view.
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
    
    
    //MARK- Update Location
    func startSetup(){
        IGLocationManager.initWithDelegate(self, secretAPIKey: "193ca2c61218e6f929626f6d35396341")
        retrieveCities()

    }
    
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
                    let coord = IGLocation(latitude: lat, longitude: lon)
                    let country = city.value["country"] as! String
                    let region = city.value["region"] as! String
                    
                    let city = City(key: key, name: name, coordinates: coord, country: country, region: region)
                    cities.append(city)
                }
                self.cities = cities
                self.determineNearestCity()
            })
    }
    
    func determineNearestCity() {
        guard let cities = self.cities else {return}
        print("determineNearestCity")
        let loc = IGLocationManager.currentLocation()

        var minDistance = Double(MAXFLOAT)
        for city in cities {
            let coords = city.getCoordinates()
            let dist = coords.distanceFromLocation(loc)

            if dist < minDistance {
                minDistance = dist
                activeCity = city
            }
        }
        
        retrieveLocationsForCity()
        
    }
    
    func retrieveLocationsForCity() {
        
        print("retrieveLocationsForCity")
        FIRDatabase.database().reference().child("locations/\(activeCity!.getKey())").observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
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
                let storyCount = child.value["story_count"] as! Int
                
                let loc = Location(key: key, name: name, coordinates: coord, imageURL: imageURL, address: address, description: description, number: number, website: website, storyCount: storyCount)
                
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
