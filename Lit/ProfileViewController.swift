//
//  ProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import ReSwift
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import UIKit

class ProfileViewController: UIViewController, StoreSubscriber {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileImageView: UIView!
    @IBOutlet weak var bioInnerBlock: UIView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var bioBlock: UIView!
    

    @IBOutlet weak var leftBlock: UIView!
    @IBOutlet weak var leftInnerBlock: UIView!
    @IBOutlet weak var leftLabel: UILabel!

    @IBOutlet weak var middleBlock: UIView!
    @IBOutlet weak var middleInnerBlock: UIView!
    @IBOutlet weak var middleLabel: UILabel!

    @IBOutlet weak var rightBlock: UIView!
    @IBOutlet weak var rightInnerBlock: UIView!
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var activityBlock: UIView!
    
    @IBOutlet weak var activityInnerBlock: UIView!
    
    @IBOutlet weak var postsBlock: UIView!
    @IBOutlet weak var postsImage: UIImageView!
    
    @IBOutlet weak var postsLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        retrievePostKeys()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let pictureRequest = FBSDKGraphRequest(graphPath: "me/picture??width=1080&height=1080&redirect=false", parameters: nil)
        pictureRequest.startWithCompletionHandler({
            (connection, result, error: NSError!) -> Void in
            if error == nil {
                let dictionary = result as? NSDictionary
                let data = dictionary?.objectForKey("data")
                let urlPic = (data?.objectForKey("url"))! as! String
                self.profileImage.loadImageUsingCacheWithURLString(urlPic, completion: {result in})
            } else {
                print("\(error)")
            }
        })
        
        //profileImage.loadImageUsingCacheWithURLString(mainStore.state.userState.user!.getImageUrl()!, completion: {result in})
        profileImage.layer.cornerRadius = profileImage.frame.width / 2
        profileImage.clipsToBounds = true
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        profileImageView.layer.shadowOpacity = 0.7
        profileImageView.layer.shadowRadius = 2
        
        bioInnerBlock.layer.cornerRadius = 4
        bioInnerBlock.clipsToBounds = true
        
        bioBlock.layer.masksToBounds = false
        bioBlock.layer.shadowOffset = CGSize(width: 0, height: 2)
        bioBlock.layer.shadowOpacity = 0.4
        bioBlock.layer.shadowRadius = 1
//        
        leftInnerBlock.layer.cornerRadius = 4
        leftInnerBlock.clipsToBounds = true
        
        leftBlock.layer.masksToBounds = false
        leftBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        leftBlock.layer.shadowOpacity = 0.7
        leftBlock.layer.shadowRadius = 2
        
        leftLabel.styleProfileBlockText(4, text: "Posts", size1: 12, size2: 18)
//
        
        middleInnerBlock.layer.cornerRadius = 4
        middleInnerBlock.clipsToBounds = true
        
        middleBlock.layer.masksToBounds = false
        middleBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        middleBlock.layer.shadowOpacity = 0.7
        middleBlock.layer.shadowRadius = 2
        
        middleLabel.styleProfileBlockText(453, text: "Friends", size1: 12, size2: 18)
        
        rightInnerBlock.layer.cornerRadius = 4
        rightInnerBlock.clipsToBounds = true
        
        rightBlock.layer.masksToBounds = false
        rightBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        rightBlock.layer.shadowOpacity = 0.7
        rightBlock.layer.shadowRadius = 2
        
        //rightLabel.styleProfileBlockText(140, text: "Reputation", size1: 12, size2: 18)
        
        activityInnerBlock.layer.cornerRadius = 4
        activityInnerBlock.clipsToBounds = true
        
        activityBlock.layer.masksToBounds = false
        activityBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        activityBlock.layer.shadowOpacity = 0.7
        activityBlock.layer.shadowRadius = 2
        
        postsImage.layer.cornerRadius = 4
        postsImage.clipsToBounds = true
        
        postsBlock.layer.masksToBounds = false
        postsBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        postsBlock.layer.shadowOpacity = 0.7
        postsBlock.layer.shadowRadius = 2

        bioLabel.text = "I am drake. Drake is me. OVO. GANG GANG GANG. Murder gang. Slaughter gang. XO. Homie G 21 21 WALK 21 21 WALK LEVELUP LEVELUP LEVELUP"

        self.navigationController?.navigationBar.topItem!.title = mainStore.state.userState.user?.getDisplayName()
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 20.0)!]
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        
    }
    
    func retrievePostKeys() {
        
        var postKeys = [String]()
        
        let postsRef = FirebaseService.ref.child("users/\(mainStore.state.userState.uid)/uploads")
        postsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                
                for post in snapshot.children {
                    postKeys.append(post.key!!)
                }
                
                FirebaseService.downloadStory(postKeys, completionHandler: { story in
                    self.setupPostsBlock(story)
                })
            }
        })
    }
    
    func setupPostsBlock(story:[StoryItem]) {
        if story.count > 0 {
            if story.count == 1 {
                postsLabel.text = "\(story.count) recent post"
            } else {
               postsLabel.text = "\(story.count) recent posts"
            }

            postsImage.hidden = false
            postsImage.loadImageUsingCacheWithURLString(story[0].getDownloadUrl()!.absoluteString, completion: { notFromCache in })
        }
        
    }
    
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
    
    
}
