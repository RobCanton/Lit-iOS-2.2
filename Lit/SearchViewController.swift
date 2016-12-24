//
//  SearchViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-31.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation

class SearchViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate,  UISearchBarDelegate {
    
    let cellIdentifier = "userCell"
    
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var statusBarBG:UIView!
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchController.active = true
    }
    
    var users = [User]()
    var locations = [Location]()
    
    var tableView:UITableView!
    var indicator = UIActivityIndicatorView()
    
    var noDataLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let topInset = navigationController!.navigationBar.frame.height
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20.0)!]
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.translucent = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        //searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView = UITableView(frame:  CGRectMake(0, 0, view.frame.width, view.frame.height))
        //tableView.contentInset = UIEdgeInsets(top: topInset + screenStatusBarHeight, left: 0, bottom: 0, right: 0)
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.backgroundColor = UIColor.clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        tableView.reloadData()
        view.backgroundColor = UIColor.clearColor()

        statusBarBG = UIView(frame: CGRectMake(0,0,view.frame.width, screenStatusBarHeight))
        statusBarBG.backgroundColor = UIColor.blackColor()
        view.addSubview(statusBarBG)
        

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurView.frame = view.bounds
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        
        searchController.delegate = self
        searchController.searchBar.backgroundColor = UIColor.blackColor()
        searchController.searchBar.delegate = self
        searchController.searchBar.searchBarStyle       = UISearchBarStyle.Minimal
        searchController.searchBar.tintColor            = UIColor.whiteColor()
        searchController.searchBar.barTintColor         = UIColor(white: 0.05, alpha: 1.0)
        searchController.searchBar.keyboardAppearance = .Dark
        
        searchController.searchBar.placeholder          = "search here";
        searchController.searchBar.sizeToFit()
        searchController.searchBar.setTextColor(UIColor.whiteColor())
        
        noDataLabel = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, 100))
        noDataLabel.text             = "No results."
        noDataLabel.textColor        = UIColor(white: 1.0, alpha: 0.5)
        noDataLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        noDataLabel.textAlignment    = .Center
        noDataLabel.center = CGPointMake(view.center.x, 100)
        noDataLabel.hidden = true
        self.view.addSubview(noDataLabel)
        
        activityIndicator()
    }
    
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        indicator.center = CGPointMake(view.center.x, 100)
        indicator.backgroundColor = UIColor.clearColor()
        indicator.hidesWhenStopped = true
        self.view.addSubview(indicator)
    }
    var task:NSURLSessionTask?
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if task != nil {
            self.stopActivityIndicator()
            task!.cancel()
        }
        if users.count == 0 && locations.count == 0 {
            showActivityIndicator()
        }
        noDataLabel.hidden = true
        if searchText.isNotEmpty && searchText.characters.count > 1 {
            let newString = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+").lowercaseString
            
            let url = NSURL(string: "\(apiURL)/search/\(newString)")
            task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    self.stopActivityIndicator()
                    //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                    self.extractFeedFromJSON(data!)
                }
            }
            
            task!.resume()
        } else {
            stopActivityIndicator()
            self.users = []
            self.locations = []
            tableView.reloadData()
        }
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
    
    func extractFeedFromJSON(data:NSData) {
        var _users = [User]()
        var _locations = [Location]()
        let json = JSON(data: data)
        if json.exists() {
            //If json is .Dictionary
            for (uid,profile):(String, JSON) in json["profiles"] {

//                let displayName      = profile["username"].stringValue
//                let imageUrl         = profile["smallProfilePicURL"].stringValue
//                let largeImageUrl    = profile["largeProfilePicURL"].stringValue
//                let numFriends       = profile["numFriends"].intValue
//                let user = User(uid: uid, displayName: displayName, imageUrl: imageUrl, largeImageUrl: largeImageUrl, numFriends: numFriends)
//                _users.append(user)
            }
            
            //If json is .Dictionary
            for (key,location):(String, JSON) in json["locations"] {
                
                let name             = location["name"].stringValue
                let lat              = location["coordinates"]["latitude"].doubleValue
                let lon              = location["coordinates"]["longitude"].doubleValue
                let imageURL         = location["imageURL"].stringValue
                let address          = location["address"].stringValue
                
                let loc = Location(key: key, name: name, latitude: lat, longitude: lon, imageURL: imageURL, address: address)
                _locations.append(loc)
            }
        }
        
        
        
        dispatch_async(dispatch_get_main_queue(), {
            self.users = _users
            self.locations = _locations
            if self.users.count == 0 && self.locations.count == 0 {
                self.noDataLabel.hidden = false
            }
            self.tableView.reloadData()
        })
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
        tableView.contentInset = UIEdgeInsetsMake(navigationController!.navigationBar.frame.height, 0, 0, 0)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return users.count
        } else if section == 1 {
            return locations.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && users.count > 0{
            return "People"
        } else if section == 1 && locations.count > 0 {
            return "Locations"
        }
        return nil
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel!.font = UIFont(name: "Avenir-Medium", size: 18.0)
        headerView.textLabel!.textColor = UIColor(white: 1.0, alpha: 0.7)
        headerView.backgroundView = nil
        headerView.backgroundColor = UIColor.clearColor()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell
        if indexPath.section == 0 {
            cell.user = users[indexPath.item]
        } else if indexPath.section == 1 {
            cell.location = locations[indexPath.item]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UserTableViewCell
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if indexPath.section == 0 {
            let controller = storyboard.instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
            controller.user = users[indexPath.item]
            self.navigationController?.pushViewController(controller, animated: true)

        } else {
            let location = locations[indexPath.item]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewControllerWithIdentifier("LocViewController") as! LocViewController
            controller.location = locations[indexPath.item]
            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            navigationController?.pushViewController(controller, animated: true)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    

    
}
