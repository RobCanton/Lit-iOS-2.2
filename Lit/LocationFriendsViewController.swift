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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    

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
        
        visitors = [String]()
        mainStore.state.friends.forEach({ friend in
            print("FRIEND: \(friend)")
            visitors.append(friend)
        })
        
        tableView.reloadData()
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int)->Int {
        return visitors.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var numOfSections = 0
        if visitors.count > 0
        {
            tableView.separatorStyle = .SingleLine
            numOfSections                = 1
            tableView.backgroundView = nil
        }
        else
        {
            let bgView = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height))
            let noDataLabel: UILabel     = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, tableView.bounds.size.height / 4
                ))
            noDataLabel.text             = "No friends are here."
            noDataLabel.textColor        = UIColor.whiteColor()
            noDataLabel.textAlignment    = .Center
            noDataLabel.center = CGPoint(x: bgView.frame.width/2, y: 30)
            bgView.addSubview(noDataLabel)
            tableView.backgroundView = bgView
            tableView.separatorStyle = .None
        }
        
        return numOfSections
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
