//
//  StoryItemViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-29.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class StoryItemViewController: UIViewController, ItemDelegate {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var authorView: UIView!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var authorName: UILabel!
    
    @IBOutlet weak var imageLayer: UIImageView!
    @IBOutlet weak var videoLayer: UIView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    var item:StoryItem!
    var isLoading = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        authorImage.layer.cornerRadius = authorImage.frame.width / 2
        authorImage.clipsToBounds = true
        
        //progressIndicator = StoryProgressIndicator(frame: CGRect(x: 12, y: 18, width: self.view.frame.width - 24, height: 2.0))
        

        // Do any additional setup after loading the view.
    }
    
    var delegate:ItemDelegate?
    
    func setStoryItem(_item:StoryItem, _delegate:ItemDelegate) {
        delegate = _delegate
        item = _item
        item.delegate = self
        imageLayer.image = nil
        
        if let _ = item.getAuthor() {
            print("Author loaded on set")
            displayAuthor()
        }
        
        if item.getContentType() == .Image {
            videoLayer.hidden = true
            if let _ = item.image {
                print("Content loaded on set")
                displayImage()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayAuthor() {
        authorImage.loadImageUsingCacheWithURLString(item.getAuthor()!.getImageUrl()!, completion: { result in})
        authorName.text = item.getAuthor()!.getDisplayName()
    }
    
    func displayImage() {
        isLoading = false
        imageLayer.image = item.image!
        delegate?.contentLoaded()
    }
    
    func displayLocation(_location:Location?) {
        if let location = _location {
            locationLabel.styleLocationTitle(location.getName())
        }
    }
    

    
    func contentLoaded() {
        print("Content loaded after set")
        displayImage()
    
    }
    
    func authorLoaded() {
        print("Author loaded after set")
        displayAuthor()
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
