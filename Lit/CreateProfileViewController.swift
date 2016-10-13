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
import MXParallaxHeader
import AudioToolbox

class CreateProfileViewController: UIViewController, UITextFieldDelegate {

    let usernameLengthLimit = 16
//    @IBOutlet weak var editorArea: UIView!
//    @IBOutlet weak var imageView: UIImageView!
//    
//    @IBOutlet weak var imageGradient: UIView!
    
    var changePictureButton:UIButton!
    var usernameField:MadokaTextField!
    var fullnameField:MadokaTextField!
    

    
    var scrollView:MXScrollView!
    var bodyView:UIView!
    var headerView:CreateProfileHeaderView!
    
    var tap: UITapGestureRecognizer!
    var continueButton:UIView!
    
    var userInfo:[String : String] = [
        "displayName": ""
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView

        scrollView = MXScrollView()
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.height = 300
        scrollView.parallaxHeader.mode = .Fill
        scrollView.parallaxHeader.minimumHeight = 20
        scrollView.frame = view.frame
        scrollView.contentSize = view.frame.size
        scrollView.backgroundColor = UIColor.blackColor()
        bodyView = UIView()
        bodyView.backgroundColor = UIColor.blackColor()
        bodyView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - scrollView.parallaxHeader.minimumHeight)
        scrollView.addSubview(bodyView)
        view.addSubview(scrollView)
        
        usernameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.75, height: 80))
        usernameField.placeholderColor = .whiteColor()
        usernameField.borderColor = .whiteColor()
        usernameField.textColor = .whiteColor()
        usernameField.placeholder = "Username (everyone)"
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Book", size: 26.0)
        usernameField.textAlignment = .Center
        usernameField.addTarget(self, action: "textViewChanged", forControlEvents: .EditingChanged);

        
        fullnameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.75, height: 80))
        fullnameField.placeholderColor = .whiteColor()
        fullnameField.borderColor = .whiteColor()
        fullnameField.textColor = .whiteColor()
        fullnameField.placeholder = "Full name (friends only)"
        fullnameField.delegate = self
        fullnameField.font = UIFont(name: "Avenir-Book", size: 26.0)
        fullnameField.textAlignment = .Center
        
        fullnameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.frame.height)
        bodyView.addSubview(fullnameField)
        
        usernameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.center.y + usernameField.frame.height + 15)
        bodyView.addSubview(usernameField)
        
        continueButton = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        continueButton.center = CGPointMake(view.frame.width/2, view.frame.height - (continueButton.frame.height/2))
        continueButton.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        let label = UILabel(frame: continueButton.bounds)
        label.text = "create profile"
        label.font = UIFont(name: "Avenir-Medium", size: 22.0)
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        continueButton.addSubview(label)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(proceed))
    
        view.addSubview(continueButton)

    }
    
    var smallProfileImageView:UIImageView!
    
    func doSet() {
        
        if let user = FIRAuth.auth()!.currentUser {
            userInfo["displayName"] = ((user.displayName ?? "").isEmpty ? "" : user.displayName!)
            userInfo["photoURL"] = ((user.photoURL?.absoluteString ?? "").isEmpty ? "" : user.photoURL!.absoluteString)
        }
        
        fullnameField.text = userInfo["displayName"]
        
        smallProfileImageView = UIImageView()
        smallProfileImageView.loadImageUsingCacheWithURLString(userInfo["photoURL"]!, completion: {result in})
        
        let pictureRequest = FBSDKGraphRequest(graphPath: "me/picture??width=1080&height=1080&redirect=false", parameters: nil)
        pictureRequest.startWithCompletionHandler({
            (connection, result, error: NSError!) -> Void in
            if error == nil {
                let dictionary = result as? NSDictionary
                let data = dictionary?.objectForKey("data")
                let urlPic = (data?.objectForKey("url"))! as! String
                self.headerView.imageView.loadImageUsingCacheWithURLString(urlPic, completion: {result in})

            } else {
                print("\(error)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func uploadLargeProfilePicture() -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}
        
        let imageRef = FirebaseService.storageRef.child("user_profiles/\(user.uid)/large")
        let image = headerView.imageView.image
        if let picData = UIImageJPEGRepresentation(image!, 0.6) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = imageRef.putData(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    func uploadSmallProfilePicture() -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}
        
        let imageRef = FirebaseService.storageRef.child("user_profiles/\(user.uid)/small")
        let image = smallProfileImageView.image
        if let picData = UIImageJPEGRepresentation(image!, 1.0) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            // Upload file and metadata to the object 'images/mountains.jpg'
            let uploadTask = imageRef.putData(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    func getNewUser() {
        if let user = FIRAuth.auth()?.currentUser {
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
                    print("We here")
                    mainStore.dispatch(UserIsAuthenticated( user: _user!, flow: .ReturningUser))
                }
            })
        }
    }
    
    func proceed() {
        deactivateCreateProfileButton()
        fullnameField.enabled = false
        usernameField.enabled = false
        
        let fullname = fullnameField.text!
        let username = usernameField.text!
        
        if let user = FIRAuth.auth()?.currentUser {
            
            if let smallTask = uploadSmallProfilePicture() {
                smallTask.observeStatus(.Success, handler: { smallTaskSnapshot in
                    if let largeTask = self.uploadLargeProfilePicture() {
                        largeTask.observeStatus(.Success, handler: { largeTaskSnapshot in
                            let privateRef = FIRDatabase.database().reference().child("users_private/\(user.uid)")
                            privateRef.setValue(["fullname":fullname], withCompletionBlock: {error, ref in
                            
                                if error == nil {
                                    let publicRef = FIRDatabase.database().reference().child("users_public/\(user.uid)")
                                    publicRef.setValue([
                                        "username":username,
                                        "smallProfilePicURL": smallTaskSnapshot.metadata!.downloadURL()!.absoluteString,
                                        "largeProfilePicURL": largeTaskSnapshot.metadata!.downloadURL()!.absoluteString
                                        ], withCompletionBlock: {error, ref in
                                            if error == nil {
                                                self.getNewUser()
                                            }
                                    })
                                }
                            })
                        })
                    }
                
                })
                
            }
        }

    }
    
    func checkUsernameAvailability() {
        print("checkUsernameAvailability")
        
        let ref = FIRDatabase.database().reference().child("users_public")
        ref.queryOrderedByChild("username").queryEqualToValue(usernameField.text!).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                self.usernameTaken()
            } else {
                self.usernameAvailable()
            }
        })
    }
    
    func usernameTaken() {
        deactivateCreateProfileButton()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        usernameField.borderColor = UIColor.redColor()
        usernameField.placeholderColor = UIColor.redColor()
        usernameField.placeholderLabel.text = "Username taken"
        usernameField.shake()
        deactivateCreateProfileButton()
    }
    
    func usernameAvailable() {
        activateCreateProfileButton()
        usernameField.borderColor = UIColor.greenColor()
        usernameField.placeholderColor = UIColor.greenColor()
        usernameField.placeholderLabel.text = "Username Available"
        activateCreateProfileButton()
    }
    

    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    func textViewChanged(){
        usernameField.text = usernameField.text?.lowercaseString;
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= usernameLengthLimit
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        //[scroll setContentOffset:CGPointMake(0, (textField.superview.frame.origin.y + (textField.frame.origin.y))) animated:YES]    }
        let point = CGPointMake(0, (textField.superview!.frame.origin.y + (textField.frame.origin.y) - scrollView.parallaxHeader.view!.frame.height))
        scrollView.setContentOffset(point, animated: true)
        
        usernameField.borderColor = UIColor.whiteColor()
        usernameField.placeholderColor = UIColor.whiteColor()
        usernameField.placeholderLabel.text = "Username (everyone)"
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if usernameField.text?.characters.count > 0 {
            checkUsernameAvailability()
            //activateCreateProfileButton()
        } else {
            //disableCreateProfileButton()
        }
    }
    
    func deactivateCreateProfileButton() {
        continueButton.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        continueButton.removeGestureRecognizer(tap)
    }
    
    func activateCreateProfileButton() {
        continueButton.backgroundColor = UIColor.whiteColor()
        continueButton.addGestureRecognizer(tap)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        NSLog("progress %f", scrollView.parallaxHeader.progress)
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
