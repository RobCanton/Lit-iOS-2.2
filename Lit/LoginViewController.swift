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
import AVFoundation


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
        if state.userState.isAuth && state.userState.user != nil {
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
        
        createDirectory("location_images")
        createDirectory("temp")
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
                    FirebaseService.login(_user!)
                } else {
                    FirebaseService.logout()
                    self.activateLoginButton()
                }
            })
        } else {
            activateLoginButton()
        }
        
        //setupVideoBackground()
        
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
        
        loginManager.logInWithReadPermissions(["public_profile", "email", "user_friends", "user_photos"], fromViewController: self, handler: {(result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
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
                
                print("FACEBOOK LOGIN STUFF")
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
                    let facebook_id =  result["id"] as! String

                    print(result.debugDescription)
                    let profilePictureUrl = "https://graph.facebook.com/\(facebook_id)/picture?type=large"
                    
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
                                let ref = FirebaseService.ref.child("users/facebook/\(facebook_id)")
                                ref.setValue(_user!.getUserId())
                                FirebaseService.login(_user!)
                            } else {
                                self.createProfile()
                            }
                        })
                    }
                }
            })
        }
    }

    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    func setupVideoBackground() {
        let videoLayer = UIView(frame: self.view.bounds)
        self.view.insertSubview(videoLayer, atIndex: 0)
        let filePath = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("intro4", ofType: "mp4")!)
        videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        playerLayer!.frame = self.view.bounds
        videoLayer.layer.addSublayer(playerLayer!)
        let item = AVPlayerItem(URL: filePath)
        videoPlayer.replaceCurrentItemWithPlayerItem(item)
        videoPlayer.play()
        loopVideo(videoPlayer)
        
    }
    
    func loopVideo(videoPlayer: AVPlayer) {
        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: nil) { notification in
            videoPlayer.seekToTime(kCMTimeZero)
            videoPlayer.play()
        }
    }
}





