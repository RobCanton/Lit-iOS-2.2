//
//  UserProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import MXParallaxHeader


class UserProfileViewController: UIViewController, MXScrollViewDelegate {

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.hidesBarsOnSwipe = true
        self.navigationController?.hidesBarsOnTap = true
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.dispatch(UserViewed())
        self.navigationController?.hidesBarsOnSwipe = false
        self.navigationController?.hidesBarsOnTap = false
    }
    
    var scrollView:UIScrollView!
    var bodyView:UserProfileBodyViewController!
    var headerView:CreateProfileHeaderView!
    var user:User?
    {
        didSet{
            print("Set user!")

            headerView.imageView.loadImageUsingCacheWithURLString(user!.getLargeImageUrl(), completion: {result in})
            headerView.setUsername(user!.getDisplayName())
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = " "
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        self.navigationController?.navigationItem.backBarButtonItem?.title = " "
        
        let addFriendButton = UIBarButtonItem(image: UIImage(named:"plus"), style: .Plain, target: self, action: nil)
        self.navigationController?.navigationItem.rightBarButtonItem = addFriendButton
        
       
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
        headerView.setGradient()
        scrollView = UIScrollView()
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.height = 300
        scrollView.parallaxHeader.mode = .Fill
        scrollView.parallaxHeader.minimumHeight = 0;
        scrollView.frame = view.frame
        scrollView.contentSize = view.frame.size
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.showsVerticalScrollIndicator = false
        bodyView = UserProfileBodyViewController(nibName: "UserProfileBodyViewController", bundle: nil)
        
        addChildViewController(bodyView)
        bodyView.view.frame = scrollView.frame

        scrollView.addSubview(bodyView.view)
        bodyView.didMoveToParentViewController(self)
        
        scrollView.delegate = self
        scrollView.bounces = false
        view.addSubview(scrollView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 60))
        label.text = ""
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        scrollView.addSubview(label)
        
        let uid = mainStore.state.viewUser
        
        if uid != "" {
            FirebaseService.getUser(uid, completionHandler: { _user in
                if _user != nil {
                    self.user = _user
                    
                }
            })
        }
        

    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //print(scrollView.contentOffset.y)
        headerView.setProgress(scrollView.parallaxHeader.progress)
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
