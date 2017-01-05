//
//  UserSearchViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-04.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class UserSearchViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    var searchBarActive:Bool = false
    
    @IBAction func handleDone(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var userIds = [String]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listenToSearchResults()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToSearchResults()
    }
    
    func listenToSearchResults() {
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("api/responses/user_search/\(uid)")
        
        ref.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                var uids = [String]()
                if let failed = snapshot.value as? Bool {
 
                } else {
                    for uid in snapshot.children {
                        uids.append(uid.key!!)
                    }

                }
            
                self.userIds = uids
                self.tableView.reloadData()
                ref.removeValue()
            }
        })
    }
    
    func stopListeningToSearchResults() {
        let uid = mainStore.state.userState.uid
        let ref = FirebaseService.ref.child("api/responses/user_search/\(uid)")
        ref.removeAllObservers()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.registerNib(nib2, forCellReuseIdentifier: "UserCell")
        
        tableView.tableFooterView = UIView(frame: CGRectMake(0,0,tableView!.frame.width, 160))
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        
        searchBar.delegate = self
        
        searchBar.keyboardAppearance   = .Dark
        searchBar.searchBarStyle       = UISearchBarStyle.Minimal
        searchBar.tintColor            = UIColor.whiteColor()
        searchBar.setTextColor(UIColor.whiteColor())
        searchBar.delegate = self
    }

    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let text = searchText.lowercaseString
        searchBar.text = text
        
        if text.characters.count > 0 {
            // user did type something, check our datasource for text that looks the same
            let uid = mainStore.state.userState.uid
            let ref = FirebaseService.ref.child("api/requests/user_search/\(uid)")
            ref.setValue(searchBar.text)
        } else {
            self.userIds = [String]()
            self.tableView.reloadData()
        }
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.cancelSearching()
        self.tableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
        
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {

    }
    func cancelSearching(){
        self.searchBar.setShowsCancelButton(false, animated: true)
        self.searchBarActive = false
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userIds.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserViewCell
        cell.setupUser(userIds[indexPath.item]) 
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserViewCell
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
        controller.uid = cell.user!.getUserId()
        self.navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
