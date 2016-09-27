//
//  AuthorInfoView.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class AuthorInfoView: UIView {
    
    var imageView: UIImageView?
    var nameLabel: UILabel?
    var timeLabel: UILabel?
    var bg: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
        
        self.initialize()
    }
    
    func initialize() {
        imageView = UIImageView(frame: CGRect(x: 12, y: 12, width: 32, height: 32))
        imageView?.backgroundColor = UIColor.blackColor()
        imageView!.layer.cornerRadius = imageView!.frame.size.width / 2;
        imageView!.clipsToBounds = true;
        
        nameLabel = UILabel(frame: CGRect(x: 52, y: 18, width: self.frame.width / 2, height: self.frame.height))
        nameLabel!.font = UIFont(name: "Avenir-Light", size: 16.0)
        nameLabel!.textColor = UIColor.whiteColor()
        nameLabel!.layer.masksToBounds = false
        nameLabel!.layer.shadowOffset = CGSize(width: 0, height: 2)
        nameLabel!.layer.shadowOpacity = 0.9
        nameLabel!.layer.shadowRadius = 4

        
        timeLabel = UILabel(frame: CGRect(x: self.frame.width - 75, y: 18, width: 100, height: self.frame.height))
        timeLabel!.font = UIFont(name: "Avenir-Light", size: 16.0)
        timeLabel!.textColor = UIColor.whiteColor()
        timeLabel!.textAlignment = .Center
        timeLabel!.layer.masksToBounds = false
        timeLabel!.layer.shadowOffset = CGSize(width: 0, height: 2)
        timeLabel!.layer.shadowOpacity = 0.9
        timeLabel!.layer.shadowRadius = 4
        timeLabel!.layer.shouldRasterize = true
        
        self.addSubview(imageView!)
        self.addSubview(nameLabel!)
        self.addSubview(timeLabel!)
    }
    
    func setAuthor(author:User) {
        
        self.nameLabel!.text = author.getDisplayName()
        
        self.nameLabel!.sizeToFit()
        
        self.imageView!.loadImageUsingCacheWithURLString(author.getImageUrl()!, completion: { result in
        })
        
        let width = self.imageView!.frame.width + self.nameLabel!.frame.width + 24
    }
    
    func setTime(date:NSDate) {
        timeLabel!.text = date.timeStringSinceNow()
        timeLabel!.sizeToFit()
    }
}

