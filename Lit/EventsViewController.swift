//
//  EventsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-02.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let cellIdentifier = "eventCell"
    var imageCache = NSCache()

    
    var _events = [Event]()
    var events = [Event]()
    var images = [UIImage]()
    
    var statusBarBG:UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.events = [Event]()
        self.images = [UIImage]()
        self.tableView.reloadData()
        
        
        title = "Upcoming Events"
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        
        view.backgroundColor = UIColor.blackColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "EventCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.backgroundColor = UIColor.blackColor()
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        //view.addSubview(statusBarBG)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight)
        view.addSubview(blurView)
        activityIndicator()
        
        var count = 0
        var _images = [UIImage]()
        for event in _events {
            self.loadImage(event.getImageUrl(), completion: { image in
                _images.append(image)
                count += 1
                if count >= self._events.count {
                    self.images = _images
                    self.events = self._events
                    self.stopActivityIndicator()
                    self.tableView.reloadData()
                    self.setCellFade()
                }
            })
        }

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
    
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        indicator.center = CGPointMake(view.center.x, 100)
        indicator.backgroundColor = UIColor.clearColor()
        indicator.hidesWhenStopped = true
        self.view.addSubview(indicator)
    }
    
    func showActivityIndicator() {
        dispatch_async(dispatch_get_main_queue(), {
            self.indicator.startAnimating()
        })
    }
    
    func stopActivityIndicator() {
        dispatch_async(dispatch_get_main_queue(), {
            self.indicator.stopAnimating()
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! EventCell
        
        cell.eventImageView.image = images[indexPath.item]
        cell.setEvent(events[indexPath.item])
        

        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let image = images[indexPath.item]
        let height = (image.size.height / image.size.width) * tableView.frame.width
        return height + 72
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {

        setCellFade()
    }
    
    func setCellFade() {
        for cell in tableView.visibleCells as [UITableViewCell] {
            
            let point = tableView.convertPoint(cell.center, toView: tableView.superview)
            let threshold = tableView.frame.height - cell.frame.height
            if point.y > threshold {
                let diff = point.y - threshold
                cell.alpha = 1 - (diff / cell.frame.height)
            } else {
                cell.alpha = 1
            }
            
        }
    }
    
    
    

}
