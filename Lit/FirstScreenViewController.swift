//
//  FirstScreenViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-30.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import AVFoundation

class FirstScreenViewController: UIViewController {

    @IBOutlet weak var loginButton: UIView!
    var tap: UITapGestureRecognizer!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.layer.borderWidth = 2.0

        activateLoginButton()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoBackground()
        tap = UITapGestureRecognizer(target: self, action: #selector(initiateFBLogin))
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func activateLoginButton() {
        loginButton.addGestureRecognizer(tap)
        loginButton.layer.opacity = 1.0
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
    
    
    @IBOutlet weak var videoLayer: UIView!
    var videoPlayer: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    func setupVideoBackground() {
        let filePath = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("intro4", ofType: "mp4")!)
        videoPlayer = AVPlayer()
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        playerLayer!.frame = self.view.bounds
        self.videoLayer.layer.addSublayer(playerLayer!)
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
