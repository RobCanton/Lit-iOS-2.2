//
//  ProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileView: UIView!
    
    @IBAction func settingsTapped(sender: AnyObject) {
        
        
        
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Options", preferredStyle: .ActionSheet)
        
        // 2
        let logoutAction = UIAlertAction(title: "Logout", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            
            try! FIRAuth.auth()!.signOut()
            let loginManager = FBSDKLoginManager()
            loginManager.logOut() // this is an instance function
            mainStore.dispatch(UserIsUnauthenticated())
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            self.presentViewController(vc, animated: true, completion: nil)
            
        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        
        // 4
        optionMenu.addAction(logoutAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    let profileImage = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.image = UIImage(named: "lit-hands")
        profileImage.frame = profileView.bounds
        profileView.addSubview(profileImage)
        
        profileImage.contentMode = .ScaleAspectFill
        profileImage.layer.cornerRadius = profileView.frame.size.width / 2;
        profileImage.clipsToBounds = true;

        
        profileView.layer.masksToBounds = false
        profileView.layer.shadowOffset = CGSize(width: 0, height: 6)
        profileView.layer.shadowOpacity = 0.4
        profileView.layer.shadowRadius = 4
        
        
        self.navigationController?.navigationBar.topItem!.title = "Robert Canton"
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        
    }
    
    
}
