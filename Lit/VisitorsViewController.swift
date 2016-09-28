//
//  VisitorsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-07.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class VisitorsViewController: UIViewController, StoreSubscriber, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    
    var visitors = [String]()
    
    
    var activeLocationKey:String?
    {
        didSet{
            
            let city = mainStore.state.userState.activeCity!.getKey()
            let ref = FirebaseService.ref.child("locations/\(city)/\(activeLocationKey!)/visitors")
            ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                if snapshot.exists() {
                    var array = [String]()
                    for visitor in snapshot.children {
                        let uid = visitor.key!!
                        if uid != mainStore.state.userState.uid {
                           array.append(uid)
                        }
                    }
                    self.visitors = array
            
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated:Bool) {
       super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        let key = state.userState.activeLocationKey
        if key != activeLocationKey {
            activeLocationKey = key
        }
        tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        let nib = UINib(nibName: "VisitorCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "newVisitorCell")
        tableView.tableFooterView = UIView()
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        tableView.tableHeaderView = headerView

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int)->Int {
        return visitors.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newVisitorCell", forIndexPath: indexPath) as! VisitorCell
        cell.set(visitors[indexPath.item])
        
        
        return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
