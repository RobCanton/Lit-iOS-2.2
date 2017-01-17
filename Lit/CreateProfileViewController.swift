//
//  CreateProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-09-30.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import ReSwift
import Firebase
import UIKit
import FBSDKCoreKit
import MXParallaxHeader
import AudioToolbox

class CreateProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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
    
    var headerTap:UITapGestureRecognizer!
    let imagePicker = UIImagePickerController()
    
    var tap: UITapGestureRecognizer!
    
    
    var userInfo:[String : String] = [
        "displayName": ""
    ]
    
    func cancel() {
        FirebaseService.logout()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var doneButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(proceed))
        navigationItem.rightBarButtonItem = doneButton
        deactivateCreateProfileButton()
        
        cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
        scrollView = MXScrollView()
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.height = 300
        scrollView.parallaxHeader.mode = .Bottom
        scrollView.parallaxHeader.minimumHeight = 20
        scrollView.frame = view.frame
        scrollView.contentSize = view.frame.size
        scrollView.backgroundColor = UIColor.blackColor()
        bodyView = UIView()
        bodyView.backgroundColor = UIColor.blackColor()
        bodyView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - scrollView.parallaxHeader.minimumHeight)
        scrollView.addSubview(bodyView)
        view.addSubview(scrollView)
        
        usernameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.80, height: 64))
        usernameField.placeholderColor = .whiteColor()
        usernameField.borderColor = .whiteColor()
        usernameField.textColor = .whiteColor()
        usernameField.placeholder = "Username"
        
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
        usernameField.textAlignment = .Center
        usernameField.autocapitalizationType = .None
        usernameField.addTarget(self, action: #selector(textViewChanged), forControlEvents: .EditingChanged);
        usernameField.keyboardAppearance = .Dark

        
        fullnameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.80, height: 64))
        fullnameField.placeholderColor = .whiteColor()
        fullnameField.borderColor = .whiteColor()
        fullnameField.textColor = .whiteColor()
        fullnameField.placeholder = "Full name"
        fullnameField.delegate = self
        fullnameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
        fullnameField.textAlignment = .Center
        fullnameField.keyboardAppearance = .Dark
        
        fullnameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.frame.height)
        bodyView.addSubview(fullnameField)
        
        usernameField.center = CGPoint(x: bodyView.frame.width/2, y: fullnameField.center.y + usernameField.frame.height + 15)
        bodyView.addSubview(usernameField)
        

        
        tap = UITapGestureRecognizer(target: self, action: #selector(proceed))
        
        headerTap = UITapGestureRecognizer(target: self, action: #selector(showProfilePhotoMessagesView))
        headerView.imageView.addGestureRecognizer(headerTap)
        headerView.imageView.userInteractionEnabled = true

        imagePicker.delegate = self
        
        
        doSet()

    }
    
    func showProfilePhotoMessagesView() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let facebookActionButton: UIAlertAction = UIAlertAction(title: "Import from Facebook", style: .Destructive)
        { action -> Void in
            self.setFacebookProfilePicture()
        }
        actionSheet.addAction(facebookActionButton)
        
        let libraryActionButton: UIAlertAction = UIAlertAction(title: "Choose from Library", style: .Destructive)
        { action -> Void in
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        actionSheet.addAction(libraryActionButton)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.headerView.imageView.image = nil
            self.smallProfileImageView.image = nil
            headerView.errorLabel.hidden = true
            headerView.imageView.image = resizeImage(pickedImage, newWidth: 720)
            smallProfileImageView.image = resizeImage(pickedImage, newWidth: 150)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    var smallProfileImageView:UIImageView!
    
    var facebook_uid = ""
    
    func doSet() {
        
        if let user = FIRAuth.auth()!.currentUser {
            
            for item in user.providerData {
                facebook_uid = item.uid
            }
            
            userInfo["displayName"] = ((user.displayName ?? "").isEmpty ? "" : user.displayName!)
            userInfo["photoURL"] = ((user.photoURL?.absoluteString ?? "").isEmpty ? "" : user.photoURL!.absoluteString)
        }
        
        fullnameField.text = userInfo["displayName"]
        
        smallProfileImageView = UIImageView()
        smallProfileImageView.loadImageUsingCacheWithURLString(userInfo["photoURL"]!, completion: {result in})
        
        
        setFacebookProfilePicture()
        
    }
    
    func setFacebookProfilePicture() {
        FacebookGraph.getProfilePicture({ imageURL in
            if imageURL != nil {
                self.headerView.errorLabel.hidden = true
                self.headerView.imageView.image = nil
                self.headerView.imageView.loadImageUsingCacheWithURLString(imageURL!, completion: {result in
                    self.smallProfileImageView.image = nil
                    self.smallProfileImageView.image = resizeImage( self.headerView.imageView.image!, newWidth: 150)
                })
            } else {
                self.headerView.errorLabel.hidden = false
            }
        })
    }
    
    
    
    func getNewUser() {
        if let user = FIRAuth.auth()?.currentUser {
            
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
                    FirebaseService.login(_user!)
                    FacebookGraph.getFacebookFriends({ _userIds in
                        FirebaseService.login(_user!)
                        if _userIds.count == 0 {
                            self.performSegueWithIdentifier("showLit", sender: self)
                        } else {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.user = _user
                                self.fbFriend_uids = _userIds
                                self.performSegueWithIdentifier("toAddFriends", sender: self)
                            })
                        }
                    })
                }
            })
        }
    }
    
    var fbFriend_uids:[String]?
    var user: User?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toAddFriends" {
            let controller = segue.destinationViewController as! UsersListViewController
            controller.title = "Add Friends"
            controller.addDoneButton()
            controller.userIds = fbFriend_uids!
            controller.user = user!
        }
    }
    
    
    func proceed() {
        if usernameField.text == nil || usernameField.text == "" { return }
        
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButtonItem(barButton, animated: true)
        activityIndicator.startAnimating()
        
        
        deactivateCreateProfileButton()
        fullnameField.enabled = false
        usernameField.enabled = false
        cancelButton.enabled  = false
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: .Normal)
        
        usernameField.resignFirstResponder()
        fullnameField.resignFirstResponder()
        
        let name = fullnameField.text!
        let username = usernameField.text!
        
        if let user = FIRAuth.auth()?.currentUser {
            let largeImage = headerView.imageView.image!
            let smallImage = smallProfileImageView.image!
            UserService.uploadProfilePicture(largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
                
                if success {
                    let ref = FirebaseService.ref.child("users/facebook/\(self.facebook_uid)")
                    ref.setValue(user.uid)
                    
                    let publicRef = FIRDatabase.database().reference().child("users/profile/basic/\(user.uid)")
                    publicRef.setValue([
                        "name": name,
                        "username":username,
                        "profileImageURL": smallImageURL!
                        ], withCompletionBlock: {error, ref in
                            if error != nil {
                                print(error!.localizedDescription)
                            }
                            else {
                                let fullProfileRef = FIRDatabase.database().reference().child("users/profile/full/\(user.uid)")
                                let obj = [
                                    "largeProfileImageURL": largeImageURL!
                                ]
                                
                                fullProfileRef.setValue(obj, withCompletionBlock: {error, ref in
                                        if error != nil {
                                            print(error!.localizedDescription)
                                        }
                                        else {
                                            self.getNewUser()
                                        }
                                })
                            }
                    })
                }
            })
        }
    }
    
    func checkUsernameAvailability() {
        
        guard let text = usernameField.text else { return }
        
        if text.characters.count >= 5 {
            let ref = FIRDatabase.database().reference().child("users/profile/basic")
            ref.queryOrderedByChild("username").queryEqualToValue(usernameField.text!).observeSingleEventOfType(.Value, withBlock: { snapshot in
                if snapshot.exists() {
                    self.usernameUnavailable("Username unavailable")
                } else {
                    self.usernameAvailable()
                }
            })
        } else {
            self.usernameUnavailable("Username must be at least 5 characters")
        }
        
        
    }
    
    func usernameUnavailable(reason:String) {
        deactivateCreateProfileButton()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        usernameField.borderColor = errorColor
        usernameField.placeholderColor = errorColor
        usernameField.placeholder = reason
        usernameField.shake()
    }
    
    func usernameAvailable() {
        activateCreateProfileButton()
        usernameField.borderColor = accentColor
        usernameField.placeholderColor = accentColor
        usernameField.placeholder = "Username available"
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
        if textField === usernameField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > usernameLengthLimit { return false }
            
            // Create an `NSCharacterSet` set 
            let inverseSet = NSCharacterSet(charactersInString:".0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.componentsSeparatedByCharactersInSet(inverseSet)
            
            // Rejoin these components
            let filtered = components.joinWithSeparator("")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
        } else if textField === fullnameField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > 50 { return false }
            
            // Create an `NSCharacterSet` set
            let inverseSet = NSCharacterSet(charactersInString:" .0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.componentsSeparatedByCharactersInSet(inverseSet)
            
            // Rejoin these components
            let filtered = components.joinWithSeparator("")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            return string == filtered
        }
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField === usernameField {
            //[scroll setContentOffset:CGPointMake(0, (textField.superview.frame.origin.y + (textField.frame.origin.y))) animated:YES]    }
            let point = CGPointMake(0, (textField.superview!.frame.origin.y + (textField.frame.origin.y) - scrollView.parallaxHeader.view!.frame.height))
            scrollView.setContentOffset(point, animated: true)
            
            usernameField.borderColor = UIColor.whiteColor()
            usernameField.placeholderColor = UIColor.whiteColor()
            usernameField.placeholder = "Username"
            
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField === usernameField {
            if textField.text?.characters.count > 0 {
                checkUsernameAvailability()
            }
        }
    }
    
    func deactivateCreateProfileButton() {
        doneButton.enabled = false
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: .Normal)
    }
    
    func activateCreateProfileButton() {
        doneButton.enabled = true
        doneButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Normal)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }


    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            // Back btn Event handler
            print("back tapped")
        }
    }

}
