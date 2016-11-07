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


enum FlowState {
    case None, ReturningUser, CreateNewUser, Permissions
}
class LoginViewController: UIViewController, StoreSubscriber {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    var flowState:FlowState = .None
    
    var tap: UITapGestureRecognizer!


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
                print("CreateNewUser")
                createProfile()
                break
            case .ReturningUser:
                print("ReturningUser")
                //toSetup()
                break
            default:
                break
            }
        }
        
        if state.userState.isAuth && state.userState.user != nil {
            
            Listeners.listenToFriends()
            Listeners.listenToFriendRequests()
            Listeners.listenToConversations()
            
            self.performSegueWithIdentifier("showLit", sender: self)
            
        }
    }

    func logout() {
        try! FIRAuth.auth()!.signOut()
        mainStore.dispatch(UserIsUnauthenticated())
    }
    
    func createProfile(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("CreateProfileViewController") as! CreateProfileViewController
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.pushViewController(controller, animated: true)
    }
    

    @IBOutlet weak var loginButton: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        

        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.layer.borderWidth = 2.0
        tap = UITapGestureRecognizer(target: self, action: #selector(initiateFBLogin))
        deactivateLoginButton()
         
        if let user = FIRAuth.auth()?.currentUser {
            print("already signed in")
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
                    mainStore.dispatch(UserIsAuthenticated( user: _user!, flow: .ReturningUser))
                } else {
                   // Do nothing
                    self.activateLoginButton()
                }
            })
        } else {
            activateLoginButton()
        }
        
    }
    
    func activateLoginButton() {
        loginButton.hidden = false
        loginButton.addGestureRecognizer(tap)
    }
    
    func deactivateLoginButton() {
        loginButton.hidden = true
        loginButton.removeGestureRecognizer(tap)
    }
    
    
    


    func initiateFBLogin() {
        loginButton.layer.opacity = 0.4
        loginButton.removeGestureRecognizer(tap)
        let loginManager = FBSDKLoginManager()
        
        loginManager.logInWithReadPermissions(["public_profile", "user_photos"], fromViewController: self, handler: {(result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if (error != nil) {
                // Process error
                self.removeFbData()
                self.activateLoginButton()
            } else if result.isCancelled {
                // User Cancellation
                self.removeFbData()
                self.activateLoginButton()
            } else {
                //Success
                if result.grantedPermissions.contains("user_photos") && result.grantedPermissions.contains("public_profile") {
                    //Do work
                    self.fetchFacebookProfile()
                } else {
                    //Handle error
                    self.removeFbData()
                    self.activateLoginButton()
                }
            }
        })
    }
    
    func removeFbData() {
        //Remove FB Data
        let fbManager = FBSDKLoginManager()
        fbManager.logOut()
        FBSDKAccessToken.setCurrentAccessToken(nil)
    }
    
    func fetchFacebookProfile()
    {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    //Handle error
                } else {
                    //Handle Profile Photo URL String
                    let userId =  result["id"] as! String
                    let profilePictureUrl = "https://graph.facebook.com/\(userId)/picture?type=large"
                    
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    let fbUser = ["accessToken": accessToken, "user": result]
                    
                    let credential = FIRFacebookAuthProvider.credentialWithAccessToken(accessToken)
                    
                    
                    FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        
                        FirebaseService.getUser(user!.uid, completionHandler: { _user in
                            if _user != nil {
                                mainStore.dispatch(UserIsAuthenticated( user: _user!, flow: .ReturningUser))
                            } else {
                                // Do nothing
                                mainStore.dispatch(UserIsAuthenticated( user: nil, flow: .CreateNewUser))
                            }
                        })
                    }
                }
            })
        }
    }
}





