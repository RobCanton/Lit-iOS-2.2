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

    @IBOutlet weak var scrollView: UIScrollView!
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
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
                toCreateProfile()
                break
            case .ReturningUser:
                print("ReturningUser")
                //toSetup()
                break
            default:
                break
            }
        }
        
        if state.userState.isAuth{
            
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
    
    func toCreateProfile() {
        v2 = CreateProfileViewController(nibName: "CreateProfileViewController", bundle: nil)
        
        addChildViewController(v2)
        scrollView.addSubview(v2.view)
        v2.didMoveToParentViewController(self)
        
        v2.doSet()
        var v2Frame = v1.view.frame
        v2Frame.origin.x = self.view.frame.width
        v2.view.frame = v2Frame
        
        self.scrollView.contentSize = CGSizeMake(self.view.frame.width * 2, self.view.frame.height)
        scrollView.setContentOffset(CGPoint(x: v1.view.frame.width, y: 0), animated: true)

    }
//    func toSetup() {
//        v3 = SetupViewController(nibName: "SetupViewController", bundle: nil)
//
//        addChildViewController(v3)
//        scrollView.addSubview(v3.view)
//        v3.didMoveToParentViewController(self)
//        
//        var v3Frame = v1.view.frame
//        v3Frame.origin.x = self.view.frame.width * 2
//        v3.view.frame = v3Frame
//        
//        self.scrollView.contentSize = CGSizeMake(self.view.frame.width * 3, self.view.frame.height)
//        scrollView.setContentOffset(CGPoint(x: self.view.frame.width * 2, y: 0), animated: true)
//    }
    
    var v1:FirstScreenViewController!
    var v2:CreateProfileViewController!
    //var v3:SetupViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        v1 = FirstScreenViewController(nibName: "FirstScreenViewController", bundle: nil)
        
        addChildViewController(v1)
        scrollView.addSubview(v1.view)
        v1.didMoveToParentViewController(self)
        
        self.scrollView.contentSize = CGSizeMake(self.view.frame.width, self.view.frame.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
         
        if let user = FIRAuth.auth()?.currentUser {
            print("already signed in")
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
                    mainStore.dispatch(UserIsAuthenticated( user: _user!, flow: .ReturningUser))
                } else {
                   // Do nothing
                    self.v1.activateLoginButton()
                }
            })
        } else {
            self.v1.activateLoginButton()
        }
        
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}





