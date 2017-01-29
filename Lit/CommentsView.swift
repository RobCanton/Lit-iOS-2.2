//
//  CommentsView.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var comments = [Comment]()

    var userTapped:((uid:String)->())?
    var tableView:UITableView!
    var divider:UIView!
    required internal init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cleanUp() {
        comments = [Comment]()
        tableView.reloadData()
        divider.hidden = true
        userTapped = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        let gradient = CAGradientLayer()
        
        gradient.frame = self.bounds ?? CGRectNull
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor, UIColor.blackColor().CGColor]
        gradient.locations = [0.0, 0.05, 1.0]
        self.layer.mask = gradient
        
        tableView = UITableView(frame: self.bounds)
        
        
        let nib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "commentCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 0.1, alpha: 0)
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.backgroundColor = UIColor.clearColor()//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        self.addSubview(tableView)
        
        divider = UIView(frame: CGRectMake(8,frame.height-1,frame.width-16,1))
        divider.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        self.addSubview(divider)
        divider.hidden = true
        
        reloadTable()
        scrollBottom(false)
    }
    
    func setTableComments(comments:[Comment], animated:Bool)
    {
        self.comments = comments
        if self.comments.count > 0 {
            divider.hidden = false
        } else {
            divider.hidden = true
        }
        reloadTable()
        scrollBottom(animated)
    }

    
    func reloadTable() {
        
        tableView.reloadData()
        
        let containerHeight = self.bounds.height
        let tableHeight = tableView.contentSize.height

        if tableHeight < containerHeight {
            tableView.frame.origin.y = containerHeight - tableHeight
            tableView.scrollEnabled = false
        } else {
            tableView.frame.origin.y = 0
            tableView.scrollEnabled = true
        }
        
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath) as! CommentCell
        cell.setContent(comments[indexPath.row])
        cell.authorTapped = userTapped
        
        return cell
    }
    
    func scrollBottom(animated:Bool) {
        if comments.count > 0 {
            let lastIndex = NSIndexPath(forRow: comments.count-1, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(lastIndex, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
        }
    }
}
