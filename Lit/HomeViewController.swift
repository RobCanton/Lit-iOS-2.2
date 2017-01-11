//
//  HomeViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber, UIScrollViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var locations = [Location]()
    var filteredLocations = [Location]()
    
    var searchBarActive:Bool = false
    var searchBar:UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.navigationController?.navigationBar.titleTextAttributes =
//            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!,
//             NSForegroundColorAttributeName: UIColor.whiteColor()]
//        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "LocationTableCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "locationCell")
        
        tableView.separatorColor = UIColor(white: 0.1, alpha: 1.0)
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.tableHeaderView = nil
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        setCellAlphas()
        
        searchBar = UISearchBar()
        //searchBar.showsCancelButton = true
        searchBar.placeholder = "Search Nearby"
        searchBar.delegate = self
        
        searchBar.keyboardAppearance   = .Dark
        searchBar.searchBarStyle       = UISearchBarStyle.Minimal
        searchBar.tintColor            = UIColor.whiteColor()
        searchBar.barTintColor         = UIColor(white: 0.05, alpha: 1.0)
        searchBar.setTextColor(UIColor.whiteColor())
        
        
        self.navigationItem.titleView = searchBar
        
    }
    
    // MARK: Search
    func filterContentForSearchText(searchText:String){
        self.filteredLocations = locations.filter({ (location:Location) -> Bool in
            return location.getName().containsIgnoringCase(searchText)
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // user did type something, check our datasource for text that looks the same
        if searchText.characters.count > 0 {
            // search and reload data source
            self.searchBarActive    = true
            self.filterContentForSearchText(searchText)
            self.tableView?.contentOffset = CGPoint(x: 0, y: 0)
            self.tableView?.reloadData()
        }else{
            // if text lenght == 0
            // we will consider the searchbar is not active
            self.searchBarActive = false
            self.tableView?.reloadData()
        }
        
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.cancelSearching()
        self.tableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        print("SEARCH")
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        // we used here to set self.searchBarActive = YES
        // but we'll not do that any more... it made problems
        // it's better to set self.searchBarActive = YES when user typed something
        self.searchBar.setShowsCancelButton(true, animated: true)
        
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        // this method is being called when search btn in the keyboard tapped
        // we set searchBarActive = NO
        // but no need to reloadCollectionView
        //self.searchBarActive = false
        //self.searchBar.setShowsCancelButton(false, animated: false)
    }
    func cancelSearching(){
        self.searchBar.setShowsCancelButton(false, animated: true)
        self.searchBarActive = false
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        locations = state.locations
        locations.sortInPlace({
            
            if $0.getVisitorsCount() == $1.getVisitorsCount() {
                return $0.getDistance() < $1.getDistance()
            }
            
            return $0.getVisitorsCount() > $1.getVisitorsCount()
        })
        
        for i in 0 ..< locations.count {
            let location = locations[i]
            if location.getKey() == state.userState.activeLocationKey {
                locations.removeAtIndex(i)
                locations.insert(location, atIndex: 0)
            }
            
        }
        tableView?.reloadData()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 190
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBarActive {
            return filteredLocations.count;
        }
        return locations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath) as! LocationTableCell
        var location:Location!
        if (searchBarActive) {
            location = filteredLocations[indexPath.item]
        } else {
            location = locations[indexPath.item]
        }
        cell.setCellLocation(location)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("LocViewController") as! LocViewController
        var location:Location
        if (searchBarActive) {
            location = filteredLocations[indexPath.item]
            cancelSearching()
        } else {
            location = locations[indexPath.item]
        }

        controller.location = location
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath:
        NSIndexPath) {
        let parallaxCell = cell as! LocationTableCell
        parallaxCell.setImageViewOffSet(tableView, indexPath: indexPath)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        setCellAlphas()
    }
    
    func setCellAlphas() {
        if let _ = self.tableView.indexPathsForVisibleRows where self.tableView.indexPathsForVisibleRows?.count > 0 {
            var count = 0
            for indexPath in self.tableView.indexPathsForVisibleRows! {
                let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! LocationTableCell
                cell.setImageViewOffSet(tableView, indexPath: indexPath)
                
                if count == tableView.indexPathsForVisibleRows!.count - 1 {
                    let rectOfCellInTableView = tableView.rectForRowAtIndexPath(indexPath)
                    
                    let rectOfCellInSuperview = tableView.convertRect(rectOfCellInTableView, toView: tableView.superview)
                    let cellY = rectOfCellInSuperview.origin.y
                    let bottomPoint = self.tableView.frame.height - rectOfCellInSuperview.height
                    
                    let alpha = 1 - (cellY - bottomPoint) / rectOfCellInSuperview.height
                    cell.alpha = max(0,alpha)
                }
                count += 1
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
}