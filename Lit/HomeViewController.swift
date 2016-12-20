//
//  HomeViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 18.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "LocationTableCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "locationCell")
        
        tableView.separatorColor = UIColor(white: 0.1, alpha: 1.0)
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.tableHeaderView = nil
        self.tableView.tableFooterView = UIView()
        tableView.reloadData()
        setCellAlphas()
        
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
        return locations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath) as! LocationTableCell
        let location = locations[indexPath.item]
        cell.setCellLocation(location)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("LocViewController") as! LocViewController
        controller.location = locations[indexPath.item]
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