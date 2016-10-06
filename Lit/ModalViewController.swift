//
//  ModalViewController.swift
//  ARNZoomImageTransition
//
//  Created by xxxAIRINxxx on 2015/08/08.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit

class ModalViewController: ARNModalImageTransitionViewController, ARNImageTransitionZoomable {
    
    var item:StoryItem?
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    
    
    deinit {

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.authorImage.layer.opacity = 0
        self.authorLabel.layer.opacity = 0
        self.timeLabel.layer.opacity = 0
        self.locationLabel.layer.opacity = 0
        
        UIView.animateWithDuration(0.75, animations: {
            self.authorImage.layer.opacity = 1.0
            self.authorLabel.layer.opacity = 1.0
            self.timeLabel.layer.opacity = 1.0
            self.locationLabel.layer.opacity = 1.0
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let key = mainStore.state.viewLocationKey
        let locations = mainStore.state.locations

        for location in locations {
            if key == location.getKey() {
                self.locationLabel.styleLocationTitle(location.getName().lowercaseString, size: 32)
            }
        }
        
        authorImage.layer.cornerRadius = authorImage.frame.width/2
        authorImage.clipsToBounds = true
        authorImage.layer.opacity = 0
        authorLabel.layer.opacity = 0
        timeLabel.layer.opacity = 0
        locationLabel.layer.opacity = 0
        
        FirebaseService.getUser(item!.getAuthorId(), completionHandler: { _user in
            if let user = _user {
                self.authorLabel.text = user.getDisplayName()
                self.timeLabel.text = self.item!.getDateCreated()!.timeStringSinceNow()
                self.authorImage.loadImageUsingCacheWithURLString(user.getImageUrl()!, completion: { result in
                })
                
            }
            
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.animateWithDuration(0.75, animations: {
            self.authorImage.layer.opacity = 0
            self.authorLabel.layer.opacity = 0
            self.timeLabel.layer.opacity = 0
            self.locationLabel.layer.opacity = 0
        })
    }
    
    // MARK: - ARNImageTransitionZoomable
    
    func createTransitionImageView() -> UIImageView {
        if let _ = item {
            self.imageView.loadImageUsingCacheWithURLString(item!.getDownloadUrl()!.absoluteString, completion: { result in })
        }
        let imageView = UIImageView(image: self.imageView.image)
        imageView.contentMode = self.imageView.contentMode
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = false
        imageView.frame = self.imageView!.frame
        return imageView
    }
    
    func presentationBeforeAction() {
        self.imageView.hidden = true
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.imageView.hidden = false
    }
    
    func dismissalBeforeAction() {
        self.imageView.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        if !completeTransition {
            self.imageView.hidden = false
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
