//
//  ViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import ReSwiftRouter
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import IngeoSDK
//
class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, StoreSubscriber, IGLocationManagerDelegate {
    
    @IBOutlet weak var counterLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        print("Unsubscribed")
    }
    
    func newState(state: AppState) {
        counterLabel.text = "\(mainStore.state.userState.uid)"
        if mainStore.state.userState.isAuth {
            loginButton.enabled = false
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
                    print("City: \(mainStore.state.userState.activeCity?.getName())")
                    let city = mainStore.state.userState.activeCity
                    FirebaseService.retrieveLocationsForCity(city!.getKey())
                }
                else if mainStore.state.userState.activeLocationKey == ""{
                    print("Locations: \(mainStore.state.locations)")
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
                        
                        print("users/\(uid)/ignores/\(city)/\(nLoc.getKey()))")
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
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        
        
        FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let _ = user {
                FirebaseService.writeUser(user!)
                if let uid = user?.uid
                {
                    mainStore.dispatch(UserIsAuthenticated(uid: uid))
                }
            }
            
            
            
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        try! FIRAuth.auth()!.signOut()
        mainStore.dispatch(UserIsUnauthenticated())
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    let loginButton = FBSDKLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.loginBehavior = .Browser
        loginButton.delegate = self
        
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
        
        
        IGLocationManager.initWithDelegate(self, secretAPIKey: "193ca2c61218e6f929626f6d35396341")
        
        
        if let user = FIRAuth.auth()?.currentUser {
            mainStore.dispatch(UserIsAuthenticated(uid: user.uid))
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
}

