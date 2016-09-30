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
    }
    
    override func viewWillDisappear(animated: Bool) {
        let header = self.segmentedPager.parallaxHeader.view as! HeaderView
        header.killTimer()
        mainStore.unsubscribe(self)
    }
    var index: Int?
    var location: Location?
    {
        didSet {
            let header = self.segmentedPager.parallaxHeader.view as! HeaderView
            header.loadImage(location!.getImageURL()!)
            header.setTitle(location!.getName().uppercaseString)
            
            if let story = location?.getStory() {
                header.loadStory(story)
            } else {
                //FirebaseService.downloadLocationStory(index!)
            }
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
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.segmentedPager.backgroundColor = UIColor.whiteColor()
        
        // Parallax Header
        let header = UINib(nibName: "HeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! HeaderView
        
        self.segmentedPager.parallaxHeader.view = header
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderMode.Fill;
        self.segmentedPager.parallaxHeader.height = UltravisualLayoutConstants.Cell.featuredHeight;
        self.segmentedPager.parallaxHeader.minimumHeight = (self.navigationController?.navigationBar.frame.height)!;
        
        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName: UIFont(name: "Avenir", size: 16.0)!];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName : accentColor,
            NSFontAttributeName: UIFont(name: "Avenir", size: 16.0)!
        ]
        self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleArrow
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor(white: 0.10, alpha: 1.0)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tappedHeader:")
        self.segmentedPager.parallaxHeader.view!.addGestureRecognizer(tapGestureRecognizer)
    }

    
    func tappedHeader(gesture:UIGestureRecognizer) {
        if mainStore.state.locations[index!].getPostKeys().count > 0 {
            self.performSegueWithIdentifier("toStoryView", sender: self)
            
            let header = self.segmentedPager.parallaxHeader.view as! HeaderView
            header.killTimer()
            
            mainStore.dispatch(ViewStory(index: index!))
            mainStore.unsubscribe(self)
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, titleForSectionAtIndex index: Int) -> String {
        return ["About", "Friends", "Trends"][index];
    }
    
    override func segmentedPager(segmentedPager: MXSegmentedPager, didScrollWithParallaxHeader parallaxHeader: MXParallaxHeader) {
        let header = self.segmentedPager.parallaxHeader.view as! HeaderView
        header.setTitleSize(parallaxHeader.progress)
    }
}
