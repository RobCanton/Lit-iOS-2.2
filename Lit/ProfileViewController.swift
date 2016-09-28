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
    
    @IBOutlet weak var leftBlock: UIView!
    @IBOutlet weak var leftInnerBlock: UIView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var middleBlock: UIView!
    @IBOutlet weak var middleInnerBlock: UIView!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var rightBlock: UIView!
    @IBOutlet weak var rightInnerBlock: UIView!
    @IBOutlet weak var rightLabel: UILabel!
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
        profileView.layer.shadowOffset = CGSize(width: 0, height: 4)
        profileView.layer.shadowOpacity = 0.4
        profileView.layer.shadowRadius = 2
        
        leftInnerBlock.layer.cornerRadius = 4
        leftInnerBlock.clipsToBounds = true
        leftBlock.layer.masksToBounds = false
        leftBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        leftBlock.layer.shadowOpacity = 0.4
        leftBlock.layer.shadowRadius = 2
        
        middleInnerBlock.layer.cornerRadius = 4
        middleInnerBlock.clipsToBounds = true
        middleBlock.layer.masksToBounds = false
        middleBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        middleBlock.layer.shadowOpacity = 0.4
        middleBlock.layer.shadowRadius = 4
        
        rightInnerBlock.layer.cornerRadius = 4
        rightInnerBlock.clipsToBounds = true
        rightBlock.layer.masksToBounds = false
        rightBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        rightBlock.layer.shadowOpacity = 0.4
        rightBlock.layer.shadowRadius = 2
        
        leftLabel.styleProfileBlockText(453, text: "Friends", size1: 14, size2: 25.0)
        middleLabel.styleProfileBlockText(12, text: "Posts", size1: 14, size2: 25.0)
        rightLabel.styleProfileBlockText(120, text: "Rep", size1: 14, size2: 25.0)
        
//        leftLabel.frame = leftInnerBlock.bounds
//        leftLabel.styleProfileBlockText(4, text: "friends", size: 28.0)
//        
//        leftInnerBlock.addSubview(leftLabel)
        
        self.navigationController?.navigationBar.topItem!.title = "Robert Canton"
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        
    }
    
    
}
