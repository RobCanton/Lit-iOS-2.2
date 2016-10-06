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

class CreateProfileViewController: UIViewController, UITextFieldDelegate {

    let usernameLengthLimit = 16
    @IBOutlet weak var editorArea: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageGradient: UIView!
    
    var usernameField:MadokaTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.75, height: 90))
        usernameField.placeholderColor = .whiteColor()
        usernameField.borderColor = .whiteColor()
        usernameField.center = CGPoint(x: editorArea.frame.width/2, y: usernameField.frame.height/2)
        usernameField.textColor = .whiteColor()
        usernameField.placeholder = "Username"
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Book", size: 29.0)
        usernameField.textAlignment = .Center
        
        editorArea.addSubview(usernameField)
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        gradient.locations = [0.0 , 1.0]

        gradient.frame = imageGradient.bounds
        imageGradient.layer.insertSublayer(gradient, atIndex: 0)
        
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= usernameLengthLimit
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
