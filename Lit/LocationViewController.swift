// MXViewController.swift
//
// Copyright (c) 2015 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import MXSegmentedPager
import ReSwift

class LocationViewController: MXSegmentedPagerController, StoreSubscriber {
    
    override func viewWillAppear(animated: Bool) {
        mainStore.subscribe(self)
        print("LocationViewController Subscribed")
    }
    
    override func viewWillDisappear(animated: Bool) {
        mainStore.unsubscribe(self)
        print("LocationViewController Unsubscribed")
    }
    var index: Int?
    var location: Location?
    {
        didSet {
            let header = self.segmentedPager.parallaxHeader.view as! HeaderView
            header.setLocation(location!)
            
        }
    }
    
    func newState(state: AppState) {
        print("New State!")
        let key = state.viewLocationKey
        let locations = state.locations
        var count = 0
        for location in locations {
            if key == location.getKey() {
                index = count
                self.location = location
            }
            count += 1
        }
        
        if state.viewUser != "" {
            push(state.viewUser)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = " "
        
        
        self.segmentedPager.backgroundColor = UIColor.blackColor()
        
        // Parallax Header
        let header = UINib(nibName: "HeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! HeaderView
        
        //self.segmentedPager

        self.segmentedPager.parallaxHeader.view = header
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.Fill;
        self.segmentedPager.parallaxHeader.height = UltravisualLayoutConstants.Cell.featuredHeight;
        self.segmentedPager.parallaxHeader.minimumHeight = (self.navigationController?.navigationBar.frame.height)!;
        
        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.blackColor()
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!
        ]
        
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.blackColor()

        self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleBox
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor(white: 1.0, alpha: 1.0)
        self.segmentedPager.segmentedControl.selectionIndicatorBoxOpacity = 0
        self.segmentedPager.segmentedControl.borderType = .Left

        self.segmentedPager.backgroundColor = UIColor.blackColor()
        self.segmentedPager.pager.backgroundColor = UIColor.blackColor()
        self.segmentedPager.pager.transitionStyle = .Scroll
        

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedHeader))
        self.segmentedPager.parallaxHeader.view!.addGestureRecognizer(tapGestureRecognizer)
    }

    
    func tappedHeader(gesture:UIGestureRecognizer) {

//        if mainStore.state.locations[index!].getPostKeys().count > 0 {
//            self.performSegueWithIdentifier("toStoryView", sender: self)
//
//            mainStore.dispatch(ViewStory(index: index!))
//            mainStore.unsubscribe(self)
//        }
    }
    
    func push(uid:String) {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UserProfileViewController")
        navigationController?.pushViewController(controller, animated: true)
    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, titleForSectionAtIndex index: Int) -> String {
        return ["recent","friends", "friends"][index];
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, didScrollWithParallaxHeader parallaxHeader: MXParallaxHeader) {
        let header = self.segmentedPager.parallaxHeader.view as! HeaderView
        header.setProgress(parallaxHeader.progress)
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, didEndDraggingWithParallaxHeader parallaxHeader: MXParallaxHeader) {
        
    }
    
    
    

}
