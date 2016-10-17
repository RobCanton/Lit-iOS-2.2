////
////  PopupViewController.swift
////  Lit
////
////  Created by Robert Canton on 2016-08-17.
////  Copyright © 2016 Robert Canton. All rights reserved.
////
//
//import Foundation
//import UIKit
//import ReSwift
//import PageControls
//
//class PopupViewController: UIViewController, UIScrollViewDelegate, StoreSubscriber {
//    
//    @IBOutlet weak var scrollView: UIScrollView!
//    
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        mainStore.subscribe(self)
//    }
//    
//    override func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//        mainStore.unsubscribe(self)
//    }
//    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }
//    
//    func newState(state: AppState) {
//        let voteState = mainStore.state.userState.vote
//        switch(voteState) {
//        case .Selection:
//            scrollView.scrollEnabled = false
//            break
//        case .CheckedIn:
//            scrollView.scrollEnabled = true
//            break
//        case .NotHere:
//            scrollView.scrollEnabled = false
//            break
//        }
//    }
//    
//    var ratingViewController: RatingViewController!
//    var cameraViewController: CameraViewController!
//    var visitorsViewController: VisitorsViewController!
//    
//
//    @IBOutlet weak var pageControl: FilledPageControl!
//    var locked = true
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        scrollView.delegate = self
//     
//        
//       self.view.backgroundColor = UIColor.blackColor()
//        ratingViewController = RatingViewController(nibName: "RatingViewController", bundle: nil)
//        cameraViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("CameraViewController") as! CameraViewController
//        visitorsViewController = VisitorsViewController(nibName: "VisitorsViewController", bundle: nil)
//        
//        self.addChildViewController(visitorsViewController)
//        self.scrollView.addSubview(visitorsViewController.view)
//        visitorsViewController.didMoveToParentViewController(self)
//        
//        self.addChildViewController(ratingViewController)
//        self.scrollView.addSubview(ratingViewController.view)
//        ratingViewController.didMoveToParentViewController(self)
//        
//        self.addChildViewController(cameraViewController)
//        self.scrollView.addSubview(cameraViewController.view)
//        cameraViewController.didMoveToParentViewController(self)
//        
//        
//        var v2Frame = visitorsViewController.view.frame
//        v2Frame.origin.x = self.view.frame.width
//        ratingViewController.view.frame = v2Frame
//        
//        var v3Frame = ratingViewController.view.frame
//        v3Frame.origin.x = self.view.frame.width * 2
//        cameraViewController.view.frame = v3Frame
//        
//        self.scrollView.contentSize = CGSizeMake(self.view.frame.width * 3, self.view.frame.height)
//        self.view.frame=CGRectMake(0, 0, self.view.frame.width * 3, self.view.frame.height);
//        scrollView.scrollEnabled = false
//        
//        self.scrollView.setContentOffset(CGPoint(x: self.view.frame.width / 3, y: 0), animated: false)
//        
//        ratingViewController.view.alpha = 1.0
//        
//        pageControl.progress = 1.0
//        
//    }
//    
//    func movetoVisitors() {
//        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//    }
//    
//    func movetoCamera() {
//        self.scrollView.setContentOffset(CGPoint(x: ratingViewController.view.frame.width * 2, y: 0), animated: false)
//    }
//    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
////        ratingViewController.view.alpha = 1 - (scrollView.contentOffset.x) / ratingViewController.view.frame.width
//        
//        let center = visitorsViewController.view.frame.width
//        let diff = scrollView.contentOffset.x - center
//        
//        let absDiff = abs(diff)
//        let alpha = max(1 - (absDiff * 1.3) / center, 0)
//        
//        ratingViewController.view.alpha = alpha
//        
//        let page = scrollView.contentOffset.x / scrollView.bounds.width
//        let progressInPage = scrollView.contentOffset.x - (page * scrollView.bounds.width)
//        let progress = CGFloat(page) + progressInPage
//        pageControl.progress = progress
//
//    }
//}