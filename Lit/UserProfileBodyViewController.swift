//
//  UserProfileBodyViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserProfileBodyViewController: UIViewController {

    @IBOutlet weak var headerBar: UIView!
    
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var repLabel: UILabel!
    
    var postTap:UITapGestureRecognizer!
    var friendsTap:UITapGestureRecognizer!
    var repTap:UITapGestureRecognizer!
    
    @IBOutlet weak var pager: UIScrollView!
    
    var v1:PostsViewController!
    var v2:PostsViewController!
    var v3:PostsViewController!
    
    func addFriendView() {
        v2 = PostsViewController(nibName: "PostsViewController", bundle: nil)
        v2.view.backgroundColor = UIColor.blackColor()
        addChildViewController(v2)
        pager.addSubview(v2.view)
        v2.didMoveToParentViewController(self)
        
        var v2Frame = v1.view.frame
        v2Frame.origin.x = self.view.frame.width
        v2.view.frame = v2Frame

        pager.contentSize = CGSizeMake(self.v1.view.frame.width * 2, self.view.frame.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pager.pagingEnabled = true
        pager.decelerationRate = UIScrollViewDecelerationRateFast
        
        v1 = PostsViewController(nibName: "PostsViewController", bundle: nil)

        v1.view.backgroundColor = UIColor.blackColor()
        
        addChildViewController(v1)
        pager.addSubview(v1.view)
        v1.didMoveToParentViewController(self)
        pager.scrollEnabled = false
        
        postsLabel.superview?.layer.borderWidth = 1.5
        postsLabel.superview?.layer.borderColor = UIColor.blackColor().CGColor
        friendsLabel.superview?.layer.borderColor = UIColor.blackColor().CGColor
        repLabel.superview?.layer.borderColor = UIColor.blackColor().CGColor
        
        postsLabel.styleProfileBlockText(4, text: "Posts", color: UIColor.blackColor())
        friendsLabel.styleProfileBlockText(6, text: "Friends", color: UIColor.whiteColor())
        repLabel.styleProfileBlockText(120, text: "Reputation", color: UIColor.whiteColor())
        
        postTap = UITapGestureRecognizer(target: self, action: #selector(postsTapped))
        friendsTap = UITapGestureRecognizer(target: self, action: #selector(friendsTapped))
        repTap = UITapGestureRecognizer(target: self, action: #selector(repTapped))
        
        postsLabel.superview?.addGestureRecognizer(postTap)
        friendsLabel.superview?.addGestureRecognizer(friendsTap)
        repLabel.superview?.addGestureRecognizer(repTap)
        // Do any additional setup after loading the view.

    }
    
    func postsTapped(gesture:UITapGestureRecognizer) {
        pager.setContentOffset(CGPointMake(0, 0), animated: false)
        postsLabel.superview?.layer.borderWidth = 1.5
        friendsLabel.superview?.layer.borderWidth = 0
        repLabel.superview?.layer.borderWidth = 0
        postsLabel.textColor = UIColor.blackColor()
        friendsLabel.textColor = UIColor.whiteColor()
        repLabel.textColor = UIColor.whiteColor()
        postsLabel.superview?.backgroundColor = UIColor.whiteColor()
        friendsLabel.superview?.backgroundColor = UIColor.blackColor()
        repLabel.superview?.backgroundColor = UIColor.blackColor()
    }
    func friendsTapped(gesture:UITapGestureRecognizer) {
        if v2 == nil {
            addFriendView()
        }
        postsLabel.superview?.layer.borderWidth = 0
        friendsLabel.superview?.layer.borderWidth = 1.5
        repLabel.superview?.layer.borderWidth = 0
        pager.setContentOffset(CGPointMake(v1.view.frame.width, 0), animated: false)
        postsLabel.textColor = UIColor.whiteColor()
        friendsLabel.textColor = UIColor.blackColor()
        repLabel.textColor = UIColor.whiteColor()
        friendsLabel.superview?.backgroundColor = UIColor.whiteColor()
        postsLabel.superview?.backgroundColor = UIColor.blackColor()
        repLabel.superview?.backgroundColor = UIColor.blackColor()
        
    }
    
    func repTapped(gesture:UITapGestureRecognizer) {
        postsLabel.superview?.layer.borderWidth = 0
        friendsLabel.superview?.layer.borderWidth = 0
        repLabel.superview?.layer.borderWidth = 1.5
        postsLabel.textColor = UIColor.whiteColor()
        friendsLabel.textColor = UIColor.whiteColor()
        repLabel.textColor = UIColor.blackColor()
        repLabel.superview?.backgroundColor = UIColor.whiteColor()
        friendsLabel.superview?.backgroundColor = UIColor.blackColor()
        postsLabel.superview?.backgroundColor = UIColor.blackColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
