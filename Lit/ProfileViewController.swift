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
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.5
        profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        
        //profileImage.loadImageUsingCacheWithURLString(mainStore.state.userState.user!.getImageUrl()!, completion: {result in})
        
        //leftBlock.layer.borderWidth = 2.0
        //leftBlock.layer.borderColor = UIColor.whiteColor().CGColor
        
        leftLabel.styleProfileBlockText(4, text: "Posts", size1: 12, size2: 18)

        //middleBlock.layer.borderWidth = 2.0
        //middleBlock.layer.borderColor = UIColor.whiteColor().CGColor
        
        middleLabel.styleProfileBlockText(453, text: "Friends", size1: 12, size2: 18)
        
        //rightBlock.layer.borderWidth = 2.0
        //rightBlock.layer.borderColor = UIColor.whiteColor().CGColor
        
        //rightLabel.styleProfileBlockText(140, text: "Reputation", size1: 12, size2: 18)
        
        //activityBlock.layer.borderWidth = 2.0
        //activityBlock.layer.borderColor = UIColor.whiteColor().CGColor
        
        postsImage.layer.cornerRadius = 4
        postsImage.clipsToBounds = true
        
        postsBlock.layer.masksToBounds = false
        postsBlock.layer.shadowOffset = CGSize(width: 0, height: 4)
        postsBlock.layer.shadowOpacity = 0.7
        postsBlock.layer.shadowRadius = 2

        bioLabel.text = "I'm 21. I enjoy short walks on the beach. The shorter the better. In fact I'd rather be walking home. Or just not walking in general. I'd rather be eating."

        //self.navigationController?.navigationBar.topItem!.title = mainStore.state.userState.user?.getDisplayName()
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
            self.dismissViewControllerAnimated(true, completion: {})
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let vc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
//            self.presentViewController(vc, animated: true, completion: nil)
            
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
