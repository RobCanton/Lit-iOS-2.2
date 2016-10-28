//
//  ActivityFeedViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift
import SwiftyJSON

class ActivityFeedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
 
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var photos = [StoryItem]()
    var collectionView:UICollectionView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        collectionView!.pagingEnabled = true
        collectionView!.showsVerticalScrollIndicator = true
        
        collectionView!.backgroundColor = UIColor.blackColor()
        view.addSubview(collectionView!)


    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        requestActivityFeed()
    }
    
    func requestActivityFeed() {
        let uid = mainStore.state.userState.uid
        let url = NSURL(string: "http://159.203.16.13:4278/api/activityfeed/\(uid)")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                self.extractFeedFromJSON(data!)
            }
        }
        
        task.resume()
    }
    
    func extractFeedFromJSON(data:NSData) {
        var postKeys = [String]()
        let json = JSON(data: data)
        if json["activity"].exists() {
            //If json is .Dictionary
            for (index,subJson):(String, JSON) in json["activity"] {
                //Do something you want
                let item = subJson.stringValue
                postKeys.append(item)
            }
        }
        downloadMedia(postKeys)
    }
    
    func downloadMedia(postKeys:[String]) {
        FirebaseService.downloadStory(postKeys, completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        cell.setPhoto(photos[indexPath.item])
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return getItemSize(indexPath)
    }
    
    func getItemSize(indexPath:NSIndexPath) -> CGSize {
        return CGSize(width: screenWidth/3, height: screenWidth/3);
    }
    
}
