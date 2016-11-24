//
//  EventTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.blackColor()
        
        collectionView.registerClass(EventCollectionViewCell.self, forCellWithReuseIdentifier: "eventCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    let margin:CGFloat = 50.0
    var events = [Event]() {
        didSet{
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: bounds.size.width, height: bounds.size.height)
            layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.scrollDirection = .Horizontal
            collectionView.setCollectionViewLayout(layout, animated: false)
        }
    }
    

    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return events.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("eventCell", forIndexPath: indexPath) as! EventCollectionViewCell
        let event = events[indexPath.item]
        cell.content.loadImageUsingCacheWithURLString(event.getImageUrl(), completion: {result in })
        cell.clipsToBounds = true
        return cell
    }
}

public class EventCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tap)
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        print("Show next item")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let width: CGFloat = (self.bounds.width)
        let height: CGFloat = (self.bounds.height)
        let frame: CGRect = CGRect(x: 12, y: 0, width: width - 24.0, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.blackColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        view.layer.cornerRadius = 4
        
        return view
    }()
}

