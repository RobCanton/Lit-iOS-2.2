////
////  SetupViewController.swift
////  Lit
////
////  Created by Robert Canton on 2016-10-07.
////  Copyright © 2016 Robert Canton. All rights reserved.
////
//
//import Firebase
//import UIKit
//import ReSwift
//import CoreLocation
//import SwiftyJSON
//
//
//class SetupViewController: UIViewController, StoreSubscriber, GPSServiceDelegate {
//
//
//    let locationManager = CLLocationManager()
//    
//    
//    @IBOutlet weak var enableLocationServicesButton: UIView!
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        mainStore.subscribe(self)
//    }
//    
//    override func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        mainStore.unsubscribe(self)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        GPSService.sharedInstance.delegate = self
//        retrieveCities()
//    }
//    
//    func tracingLocation(currentLocation: CLLocation){
//        //LocationService.sharedInstance.stopUpdatingLocation()
//        requestNearbyLocations(currentLocation)
//    }
//    
//    func tracingLocationDidFailWithError(error: NSError) {
//    
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    func newState(state: AppState) {
//        
//    }
//    
//    var cities:[City]?
//    var activeCity:City?
//    var locations:[Location]?
//    func retrieveCities() {
//        print("retrieveCities")
//        FIRDatabase.database().reference().child("cities")
//            .observeSingleEventOfType(.Value, withBlock: {(snapshot) in
//                var cities = [City]()
//                for city in snapshot.children {
//                    let key = city.key!!
//                    let name = city.value["name"] as! String
//                    let lat = city.childSnapshotForPath("coordinates").value!["latitude"] as! Double
//                    let lon = city.childSnapshotForPath("coordinates").value!["longitude"] as! Double
//                    let coord = CLLocation(latitude: lat, longitude: lon)
//                    let country = city.value["country"] as! String
//                    let region = city.value["region"] as! String
//                    
//                    let city = City(key: key, name: name, coordinates: coord, country: country, region: region)
//                    cities.append(city)
//                }
//                self.cities = cities
//                GPSService.sharedInstance.startUpdatingLocation()
//            })
//    }
//    
//    func requestNearbyLocations(coordinate:CLLocation) {
//        let lat = coordinate.coordinate.latitude
//        let lon = coordinate.coordinate.longitude
//        let uid = mainStore.state.userState.uid
//        let url = NSURL(string: "\(apiURL)/nearby/50/\(lat)/\(lon)")
//        print("Requesting Nearby Locations: \(url!.absoluteString)")
//        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
//            if error != nil {
//                print(error!.localizedDescription)
//            } else {
//                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
//                self.extractFeedFromJSON(data!)
//            }
//        }
//        
//        task.resume()
//    }
//    
//
//    
//    func setupComplete() {
//        print("Setup complete")
//
//        guard let locations  = self.locations else {return}
//
//        mainStore.dispatch(LocationsRetrieved(locations: locations))
//        
//        //Listeners.listenToLocations()
//        Listeners.listenToFriends()
//        Listeners.listenToFriendRequests()
//        Listeners.listenToConversations()
//        
//    }
//
//}
