//
//  EventsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-02.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EventsViewController: UITableViewController {
    
    var imageCache = NSCache()
    
    var location:Location!
    
    var events = [Event]()
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.blackColor()
        
        FirebaseService.getLocationEvents(location.getKey(), completionHandler: { events in
            var images = [UIImage]()
            var count = 0
            for event in events {
                self.loadImage(event.getImageUrl(), completion: { image in
                    images.append(image)
                    count += 1
                    
                    print("\(event.getImageUrl()) ratio: \(image.size.width / image.size.height)")
                    if count >= events.count {
                        self.images = images
                        self.events = events
                        self.tableView.reloadData()
                        
                    }
                })
            }
        })
    }
    
    func loadImage(_url:String, completion: (image: UIImage)->()) {
        
        // Check for cached image
        if let cachedImage = imageCache.objectForKey(_url) as? UIImage {

            return completion(image: cachedImage)
        }
        
        // Otherwise, download image
        let url = NSURL(string: _url)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
            { (data, response, error) in
                
                //error
                if error != nil {
                    if error?.code == -999 {
                        return
                    }
                    print(error?.code)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        self.imageCache.setObject(downloadedImage, forKey: _url)
                    }
                    return completion(image: UIImage(data: data!)!)
                })
                
        }).resume()
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell", forIndexPath: indexPath) as! EventCell
        
        cell.eventImageView.image = images[indexPath.item]
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let image = images[indexPath.item]
        let height = (image.size.height / image.size.width) * tableView.frame.width
        return height
    }
    
    
    

}
