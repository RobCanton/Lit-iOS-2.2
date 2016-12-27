//
//  EditProfilePictureView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EditProfilePictureView: UIView {
    
    
    var handler:(()->())?
    
    var imageTap: UITapGestureRecognizer!
    
    @IBOutlet weak var imageView: UIImageView!
    
    

    @IBAction func handleButton(sender: AnyObject) {
        print("Change Profile Picture")
        handler?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setImage(url:String) {
        
        
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            self.imageView.layer.cornerRadius = self.imageView.frame.width / 2
            self.imageView.clipsToBounds = true
            self.imageView.image = image
            
            self.imageTap = UITapGestureRecognizer(target: self, action: #selector(self.handleChange))
            self.imageView.userInteractionEnabled = true
            self.imageView.addGestureRecognizer(self.imageTap)
        })
    }
    
    func handleChange() {
        print("YO!")
        handler?()
    }

}
