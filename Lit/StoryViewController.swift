//
//  StoryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol StoryViewDelegate {
    func storyComplete()
}

public class StoryViewController: UICollectionViewCell {
    
    var viewIndex = 0
    
    var delegate:StoryViewDelegate?
    
    var tap:UITapGestureRecognizer!
    var story:Story!
    {
        didSet {
            if story.getItems().count == 0 { return }
            self.addGestureRecognizer(tap)
            viewIndex = 0
            setItem()
            
            
        }
    }
    
    func setItem() {
        if viewIndex < story.getItems().count {
            let item = story.getItems()[viewIndex]
            content.loadImageUsingCacheWithURLString(item.getDownloadUrl()!.absoluteString, completion: {result in })
        } else {
            self.removeGestureRecognizer(tap)
            delegate?.storyComplete()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
    }
    
    func tapped(gesture:UITapGestureRecognizer) {
        viewIndex += 1
        setItem()
        print("Show next item")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let margin: CGFloat = 2.0
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.blackColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
}
