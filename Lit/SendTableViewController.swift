//
//  SendTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class SendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func handleReturn(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "profileCell")
        
        let nib2 = UINib(nibName: "SendLocationViewCell", bundle: nil)
        tableView.registerNib(nib2, forCellReuseIdentifier: "locationCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView.reloadData()
        
        
    }
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 34
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 1 {
            let headerView = UINib(nibName: "ListHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ListHeaderView
            headerView.hidden = false
            headerView.label.text = "NEARBY"
            return headerView
        }
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileCell", forIndexPath: indexPath)
                as! SendProfileViewCell
            
            if indexPath.row == 0 {
                cell.label.text = "My Profile"
                cell.subtitle.text = ""
            } else if indexPath.row == 1 {
                cell.label.text = "My Story"
                cell.subtitle.text = "(Lasts 24 hours)"
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileCell", forIndexPath: indexPath)
                as! SendProfileViewCell
            
            let location = mainStore.state.locations[0]
            cell.label.text = location.getName()
            return cell
        }
        
    }
    
    

}
