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
import SwiftMessages

class CreateProfileViewController: UIViewController, StoreSubscriber, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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
    
    var headerTap:UITapGestureRecognizer!
    let imagePicker = UIImagePickerController()
    
    var tap: UITapGestureRecognizer!
    var continueButton:UIView!
    
    var profilePhotoMessageView:ProfilePictureMessageView?
    var config: SwiftMessages.Config?
    var profilePhotoMessageWrapper = SwiftMessages()
    
    var userInfo:[String : String] = [
        "displayName": ""
    ]
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state:AppState) {
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Profile"
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(proceed))

        navigationItem.rightBarButtonItem = doneButton
        self.automaticallyAdjustsScrollViewInsets = false
        
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
        headerView.locationIcon.hidden = true
        headerView.locationLabel.hidden = true
        headerView.bioTextView.hidden = true
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
        usernameField.placeholder = "Username (everyone)"
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
        usernameField.textAlignment = .Center
        usernameField.autocapitalizationType = .None
        usernameField.addTarget(self, action: "textViewChanged", forControlEvents: .EditingChanged);

        
        fullnameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.80, height: 64))
        fullnameField.placeholderColor = .whiteColor()
        fullnameField.borderColor = .whiteColor()
        fullnameField.textColor = .whiteColor()
        fullnameField.placeholder = "Full name (friends only)"
        fullnameField.delegate = self
        fullnameField.font = UIFont(name: "Avenir-Medium", size: 20.0)
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
        label.font = UIFont(name: "Avenir-Medium", size: 20.0)
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        
        tap = UITapGestureRecognizer(target: self, action: #selector(proceed))
        
        headerTap = UITapGestureRecognizer(target: self, action: #selector(showProfilePhotoMessagesView))
        headerView.imageView.addGestureRecognizer(headerTap)
        headerView.imageView.userInteractionEnabled = true
    
        view.addSubview(continueButton)
        imagePicker.delegate = self
        
        doSet()

    }
    
    func showProfilePhotoMessagesView() {
        profilePhotoMessageView = try! SwiftMessages.viewFromNib() as? ProfilePictureMessageView
        profilePhotoMessageView!.configureDropShadow()
        
        profilePhotoMessageView!.facebookHandler = {
            self.profilePhotoMessageWrapper.hide()
            self.setFacebookProfilePicture()
        }
        
        profilePhotoMessageView!.libraryHandler = {
            self.profilePhotoMessageWrapper.hide()
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        
        profilePhotoMessageView!.cancelHandler = {
            self.profilePhotoMessageWrapper.hide()
        }
        
        config = SwiftMessages.Config()
        config!.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config!.duration = .Forever
        config!.presentationStyle = .Bottom
        config!.dimMode = .Gray(interactive: true)
        profilePhotoMessageWrapper.show(config: config!, view: profilePhotoMessageView!)
    }
    
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.headerView.imageView.image = nil
            self.smallProfileImageView.image = nil
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
                print("LIKE WE HERE \(imageURL!)")
                self.headerView.imageView.image = nil
                self.headerView.imageView.loadImageUsingCacheWithURLString(imageURL!, completion: {result in
                    self.smallProfileImageView.image = nil
                    self.smallProfileImageView.image = resizeImage( self.headerView.imageView.image!, newWidth: 150)
                })
            }
        })
    }
    
    
    
    func getNewUser() {
        if let user = FIRAuth.auth()?.currentUser {
            
            FirebaseService.getUser(user.uid, completionHandler: { _user in
                if _user != nil {
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
        deactivateCreateProfileButton()
        fullnameField.enabled = false
        usernameField.enabled = false
        
        let fullname = fullnameField.text!
        let username = usernameField.text!
        
        if let user = FIRAuth.auth()?.currentUser {
            let largeImage = headerView.imageView.image!
            let smallImage = smallProfileImageView.image!
            UserService.uploadProfilePicture(largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
                
                if success {
                    let ref = FirebaseService.ref.child("users/facebook/\(self.facebook_uid)")
                    ref.setValue(user.uid)
                    
                    let privateRef = FIRDatabase.database().reference().child("users/private/\(user.uid)")
                    privateRef.setValue([
                        "fullname":fullname
                        ], withCompletionBlock: {error, ref in
                            if error != nil {
                                return print(error?.localizedDescription)
                            }

                            let publicRef = FIRDatabase.database().reference().child("users/profile/\(user.uid)")
                            publicRef.setValue([
                                "username":username,
                                "smallProfilePicURL": smallImageURL!,
                                "largeProfilePicURL": largeImageURL!,
                                "numFriends":0
                                ], withCompletionBlock: {error, ref in
                                    if error != nil {
                                        print(error!.localizedDescription)
                                    }
                                    else {
                                        self.getNewUser()
                                    }
                            })
                    })
                }
            })
        }

    }
    
    func checkUsernameAvailability() {
        print("checkUsernameAvailability")
        
        let ref = FIRDatabase.database().reference().child("users/profile")
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
        usernameField.borderColor = errorColor
        usernameField.placeholderColor = errorColor
        usernameField.placeholderLabel.text = "Username taken"
        usernameField.shake()
        deactivateCreateProfileButton()
    }
    
    func usernameAvailable() {
        activateCreateProfileButton()
        usernameField.borderColor = accentColor
        usernameField.placeholderColor = accentColor
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
        //return newLength <= usernameLengthLimit
        if newLength > usernameLengthLimit { return false }
        
        // Create an `NSCharacterSet` set which includes everything *but* the digits
        let inverseSet = NSCharacterSet(charactersInString:"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet
        
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
        
    }


    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            // Back btn Event handler
            print("back tapped")
        }
    }

}
