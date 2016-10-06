//
//  ViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import IngeoSDK
//
class LoginViewController: UIViewController, StoreSubscriber, IGLocationManagerDelegate {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    var flowState:FlowState = .None

    @IBOutlet weak var scrollView: UIScrollView!
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        print("Unsubscribed")
    }
    
    func newState(state:AppState) {
        
        if flowState != state.userState.flow {
            flowState = state.userState.flow
            
            switch flowState {
            case .CreateNewUser:
                toNextStep()
                break
            case .ReturningUser:
                Listeners.listenToFriends()
                Listeners.listenToFriendRequests()
                DEPRECATED_LOGIN()
                break
            default:
                break
            }
        }
//        else {
//            DEPRECATED_LOGIN()
//        }

    }
    

    
    func logout() {
        try! FIRAuth.auth()!.signOut()
        mainStore.dispatch(UserIsUnauthenticated())
    }
    
    func toNextStep() {
        scrollView.setContentOffset(CGPoint(x: v1.view.frame.width, y: 0), animated: true)
        v2.doSet()
    }
    
    var v1:FirstScreenViewController!
    var v2:CreateProfileViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        v1 = FirstScreenViewController(nibName: "FirstScreenViewController", bundle: nil)
        
        addChildViewController(v1)
        scrollView.addSubview(v1.view)
        v1.didMoveToParentViewController(self)
        
        v2 = CreateProfileViewController(nibName: "CreateProfileViewController", bundle: nil)
        
        addChildViewController(v2)
        scrollView.addSubview(v2.view)
        v2.didMoveToParentViewController(self)
        
        var v2Frame = v1.view.frame
        v2Frame.origin.x = self.view.frame.width
        v2.view.frame = v2Frame
        
        self.scrollView.contentSize = CGSizeMake(self.view.frame.width * 2, self.view.frame.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        
        IGLocationManager.initWithDelegate(self, secretAPIKey: "193ca2c61218e6f929626f6d35396341")
        
        if let user = FIRAuth.auth()?.currentUser {
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
                    mainStore.dispatch(UserIsAuthenticated( user: _user!, flow: .ReturningUser))
                } else {
                   // Do nothing
                }
            })
        }
    }
    

    
    func igLocationManager(manager: IGLocationManager!, didUpdateLocation igLocation: IGLocation!) {
        print("didUpdateLocation: \(igLocation.description)")
        //mainStore.dispatch(UpdateUserLocaiton(igLocation))
    }
    
    func igLocationManager(manager: IGLocationManager!, didDetectMotionState motionState: IGMotionState) {
        print("didDetectMotionState: \(IGLocation.stringForMotionState(motionState))")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
        func DEPRECATED_LOGIN() {
            
            let cities = mainStore.state.cities
            if cities.count == 0 {
                FirebaseService.retrieveCities()
            } else {
                
                if mainStore.state.userState.coordinates == nil{
                    let loc = IGLocationManager.currentLocation()
                    mainStore.dispatch(UpdateUserLocation(location: loc))
                } else if mainStore.state.userState.activeCity == nil {
                    if let loc = mainStore.state.userState.coordinates {
                        var nearestCity:City?
                        var minDistance = Double(MAXFLOAT)
                        for city in mainStore.state.cities {
                            let coords = city.getCoordinates()
                            let dist = coords.distanceFromLocation(loc)
                            
                            if dist < minDistance {
                                minDistance = dist
                                nearestCity = city
                            }
                        }
                        
                        if let _ = nearestCity {
                            mainStore.dispatch(SetActiveCity(city: nearestCity!))
                            
                        }
                    }
                } else if mainStore.state.locations.count == 0 {
                    // get locations
                    let city = mainStore.state.userState.activeCity
                    FirebaseService.retrieveLocationsForCity(city!.getKey())
                }
                else if mainStore.state.userState.activeLocationKey == ""{
                    Listeners.listenToLocations()
                    var minDistance = Double(MAXFLOAT)
                    var nearestLocation:Location?
                    for location in mainStore.state.locations {
                        let coords = location.getCoordinates()
                        let igCoords = IGLocation(latitude: coords.coordinate.latitude, longitude: coords.coordinate.longitude)
                        let dist = igCoords.distanceFromLocation(mainStore.state.userState.coordinates!)
                        
                        if dist < minDistance {
                            minDistance = dist
                            nearestLocation = location
                        }
                    }
                    
                    if let nLoc = nearestLocation {
                        let uid = mainStore.state.userState.uid
                        let city = mainStore.state.userState.activeCity!.getKey()
                        
                        let ignoreRef = FirebaseService.ref.child("users/\(uid)/ignores/\(city)/\(nLoc.getKey())")
                        ignoreRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                            
                            if snapshot.exists() {
                                // block
                                // TODO MOVE THIS TO MAIN VIEW
                                self.performSegueWithIdentifier("showLit", sender: self)
                            } else {
                                mainStore.dispatch(SetActiveLocation(locationKey: nearestLocation!.getKey()))
                            }
                        })
                    }
                } else {
                    
                    self.performSegueWithIdentifier("showLit", sender: self)
                }
            }
        }
    
}





