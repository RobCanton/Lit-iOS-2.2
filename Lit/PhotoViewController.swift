//
//  PhotoViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var activeImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = item {
            activeImageView.loadImageUsingCacheWithURLString(item!.getDownloadUrl()!.absoluteString, completion: {result in})
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    var item:StoryItem?
    
    func setPhotoItemTing(_item:StoryItem) {
        item = _item

    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {

    }
}
