//
//  CreateProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-30.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import UIKit
import FBSDKCoreKit

class CreateProfileViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let textField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
//        textField.placeholderColor = .grayColor()
//        textField.borderColor = UIColor.whiteColor()
//        textField.center = view.center
//        textField.textColor = UIColor.whiteColor()
//        textField.placeholder = "First Name"
//        
//        view.addSubview(textField)
        
        
        

        // Do any additional setup after loading the view.
    }
    
    func doSet() {
        let pictureRequest = FBSDKGraphRequest(graphPath: "me/picture??width=1080&height=1080&redirect=false", parameters: nil)
        pictureRequest.startWithCompletionHandler({
            (connection, result, error: NSError!) -> Void in
            if error == nil {
                let dictionary = result as? NSDictionary
                let data = dictionary?.objectForKey("data")
                let urlPic = (data?.objectForKey("url"))! as! String
                self.imageView.loadImageUsingCacheWithURLString(urlPic, completion: {result in})
            } else {
                print("\(error)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
