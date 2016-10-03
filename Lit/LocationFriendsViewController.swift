//
//  LocationFriendsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-03.
//  Copyright © 2016 Robert Canton. All rights reserved.
//


import UIKit

class LocationFriendsViewController: UITableViewController {
    var location: Location?
    
    var visitors = [String]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.blackColor()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let nib = UINib(nibName: "VisitorCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "newVisitorCell")
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 120))
        
        let key = mainStore.state.viewLocationKey
        let locations = mainStore.state.locations
        
        for location in locations {
            if location.getKey() == key {
                self.location = location
            }
        }
        
        visitors = ["OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2",
                    "OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2","OIuO11QAAlN4ID2VjF4VhF7dd8X2"]
        tableView.reloadData()
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int)->Int {
        return visitors.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newVisitorCell", forIndexPath: indexPath) as! VisitorCell
        cell.set(visitors[indexPath.item])
        
        return cell
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
}
