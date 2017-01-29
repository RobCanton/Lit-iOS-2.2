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
        
        
        deactivateLoginButton()
        
        if !mainStore.state.userState.supportedVersion {
            
            checkIfViableVersion({ viable in
                if viable {
                    mainStore.dispatch(SupportedVersion())
                    self.setupLoginScreen()
                } else {
                    self.showUpdateAlert()
                }
            })
        } else {
            setupLoginScreen()
        }
    }
    
    func setupLoginScreen() {
        
        if let user = FIRAuth.auth()?.currentUser {
            print("User already authenticated.")
            
            checkUserAgainstDatabase({success, error in
                if success {
                    FirebaseService.getUser(user.uid, completionHandler: { _user in
                        if _user != nil {
                            FirebaseService.login(_user!)
                        } else {
                            FirebaseService.logoutOfFirebase()
                            self.activateLoginButton()
                        }
                    })
                } else {
                    FirebaseService.logoutOfFirebase()
                    self.activateLoginButton()
                }
            })
            
        } else {
            FirebaseService.logoutOfFirebase()
            activateLoginButton()
        }

    }
    
    func checkUserAgainstDatabase(completion: (success: Bool, error: NSError?) -> Void) {
        guard let currentUser = FIRAuth.auth()?.currentUser else { return }
        currentUser.getTokenForcingRefresh(true) { (idToken, error) in
            if let error = error {
                completion(success: false, error: error)
                print(error.localizedDescription)
            } else {
                completion(success: true, error: nil)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        print("Unsubscribed")
        activityIndicator.stopAnimating()
    }
    
    func newState(state:AppState) {
        if state.userState.supportedVersion && state.userState.isAuth && state.userState.user != nil {
            self.performSegueWithIdentifier("showLit", sender: self)
        }
    }

    func logout() {
        try! FIRAuth.auth()!.signOut()
        mainStore.dispatch(UserIsUnauthenticated())
    }
    
    func createProfile(){
        self.performSegueWithIdentifier("createProfile", sender: self)
    }
    

    @IBOutlet weak var loginButton: UIView!

    
    var activityIndicator:UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createDirectory("location_images")
        createDirectory("temp")

        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.layer.borderWidth = 2.0
        tap = UITapGestureRecognizer(target: self, action: #selector(initiateFBLogin))
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.center = CGPoint(x: view.center.x, y: loginButton.center.y)
        self.view.addSubview(activityIndicator)
    }
    
    func showUpdateAlert() {
        let alert = UIAlertController(title: "This version is no longer supported.", message: "Please update Lit on the Appstore.", preferredStyle: .Alert)
        
        
        let update = UIAlertAction(title: "Got it", style: .Default, handler: nil)
        alert.addAction(update)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLoginScreen() {
        
    }
    
    func activateLoginButton() {
        loginButton.hidden = false
        loginButton.addGestureRecognizer(tap)
    }
    
    func deactivateLoginButton() {
        loginButton.hidden = true
        loginButton.removeGestureRecognizer(tap)
    }
    
    
    func checkIfViableVersion(completion:((viable:Bool)->())) {
        activityIndicator.startAnimating()
        let infoDictionary = NSBundle.mainBundle().infoDictionary!
        let appId = infoDictionary["CFBundleShortVersionString"] as! String
        
        let currentVersion = Int(appId.stringByReplacingOccurrencesOfString(".", withString: ""))!
        
        let fetchVersion = FirebaseService.ref.child("config/client/minimum_supported_version")
        fetchVersion.observeSingleEventOfType(.Value, withBlock: { snapshot in
            let versionString = snapshot.value! as! String
            let minimum_supported_version = Int(versionString.stringByReplacingOccurrencesOfString(".", withString: ""))!
            print("current_version: \(currentVersion) | minimum_supported_version: \(minimum_supported_version)")
            self.activityIndicator.stopAnimating()
            completion(viable: currentVersion >= minimum_supported_version)
        })

    }
    
    


    func initiateFBLogin() {
        loginButton.removeGestureRecognizer(tap)
        let loginManager = FBSDKLoginManager()
        
        loginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: self, handler: {(result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
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
                
                if result.grantedPermissions.contains("public_profile") {
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
                    
                    self.FirebaseSignInWithCredential(credential, facebook_id: facebook_id)
                }
            })
        }
    }
    
    
    func FirebaseSignInWithCredential( credential: FIRAuthCredential, facebook_id: String) {
        
        deactivateLoginButton()
    
        activityIndicator.startAnimating()
        
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





