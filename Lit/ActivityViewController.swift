//
//  ActivityViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class ActivityViewController: UITableViewController, StoreSubscriber {
    
    
    var requests = [FriendRequest]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        
        for request in requests {
            if request.getStatus() == .PENDING_INCOMING {
                let ref = FirebaseService.ref.child("users/\(mainStore.state.userState.uid)/friendRequests/\(request.getId())")
                ref.updateChildValues(["status": FriendStatus.PENDING_INCOMING_SEEN.rawValue])
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        requests = state.userState.friendRequests
        print("Requests: \(requests)")
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "ActivityFriendRequestCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "activityFriendRequestCell")
        tableView.reloadData()
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 72
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Friend Requests"
        }
        return "Activity"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("activityFriendRequestCell", forIndexPath: indexPath) as! ActivityFriendRequestCell
        cell.set(requests[indexPath.item])
        //cell.textLabel?.text = "Section \(indexPath.section) Row \(indexPath.row)"
        
        return cell
    }
    
}
