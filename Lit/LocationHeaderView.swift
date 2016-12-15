//
//  LocationHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol LocationHeaderProtocol {
    func backTapped()
    func showMap()
    func showGuests()
}

class LocationHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var addressTitle: UILabel!
    
    @IBOutlet weak var fadeCover: UIView!

    var delegate:LocationHeaderProtocol?
    
    var addressTap:UITapGestureRecognizer!
    
    @IBAction func backTapped(sender: AnyObject) {
        delegate?.backTapped()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        let gradient: CAGradientLayer = CAGradientLayer()
//        
//        gradient.colors = [UIColor.clearColor().CGColor, UIColor(white: 0.0, alpha: 0.5).CGColor]
//        gradient.locations = [0.0 , 1.0]
//        
//        gradient.frame = gradientView.bounds
//        gradientView.layer.insertSublayer(gradient, atIndex: 0)
        
    }
    
    func setProgress(progress:CGFloat) {
        if progress < -0.4 {
            let p = abs(progress)
            fadeCover.alpha = ((p - 0.4) / 0.6) * 1.75
        } else {
            fadeCover.alpha = 0
        }
    }
    var location:Location?
    func setHeaderLocation(location:Location) {
        self.location = location

        loadLocationImage(location.getImageURL() , completion: { image, fromCache in
            self.imageView.image = image
        })
        locationTitle.styleLocationTitle(location.getName(), size: 32.0)
        locationTitle.applyShadow(2, opacity: 0.8, height: 2, shouldRasterize: false)

    }
    
    func showMap(gesture:UITapGestureRecognizer) {
        delegate?.showMap()
    }
    
    func showGuests(gesture:UITapGestureRecognizer) {
        delegate?.showGuests()
    }
    
    var task:NSURLSessionDataTask?
    func loadLocationImage(_url:String, completion: (image: UIImage, fromCache:Bool)->()) {
        if task != nil{
            
            task!.cancel()
            task = nil
            
        }
        
        if let file = location!.imageOnDiskURL {
            completion(image: UIImage(contentsOfFile: file.path!)!, fromCache:true)
        } else {
            // Otherwise, download image
            let url = NSURL(string: _url)
            
            task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler:
                { (data, response, error) in
                    
                    //error
                    if error != nil {
                        if error?.code == -999 {
                            return
                        }
                        print(error?.code)
                        return
                    }
                    
                    let  documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
                    if let image = UIImage(data: data!) {
                        let fileURL = documentsURL.URLByAppendingPathComponent("location_images").URLByAppendingPathComponent("\(self.location!.getKey()).jpg")
                        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
                            jpgData.writeToURL(fileURL, atomically: true)
                            self.location!.imageOnDiskURL = fileURL
                            
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(image: UIImage(data: data!)!, fromCache: false)
                    })
                    
            })
            
            task?.resume()
        }
    }
    
}
