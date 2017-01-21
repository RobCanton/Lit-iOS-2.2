//
//  LocationHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-06.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class LocationHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setLocationDetails(location:Location) {
        
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fileURL = documentsURL.URLByAppendingPathComponent("location_images").URLByAppendingPathComponent("\(location.getKey()).jpg")
        
        if let imageFile = UIImage(contentsOfFile: fileURL.path!) {
            self.imageView.image = imageFile
        } else {
            loadImageUsingCacheWithURL(location.getImageURL(), completion: { image, fromCache in
                self.imageView.image = image
            })
        }
    }
}
