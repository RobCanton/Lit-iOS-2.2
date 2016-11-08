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
    
    var headerTap:UILongPressGestureRecognizer!
    let imagePicker = UIImagePickerController()
    
    var tap: UITapGestureRecognizer!
    var continueButton:UIView!
    
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
    
        if state.userState.isAuth && state.userState.user != nil {
            
            self.performSegueWithIdentifier("showLit", sender: self)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = " "
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        headerView = UINib(nibName: "CreateProfileHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! CreateProfileHeaderView
        headerView.locationIcon.hidden = true
        headerView.locationLabel.hidden = true
        headerView.bioTextView.hidden = true
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
        
        usernameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.85, height: 80))
        usernameField.placeholderColor = .whiteColor()
        usernameField.borderColor = .whiteColor()
        usernameField.textColor = .whiteColor()
        usernameField.placeholder = "Username (everyone)"
        usernameField.delegate = self
        usernameField.font = UIFont(name: "Avenir-Book", size: 26.0)
        usernameField.textAlignment = .Center
        usernameField.autocapitalizationType = .None
        usernameField.addTarget(self, action: "textViewChanged", forControlEvents: .EditingChanged);

        
        fullnameField = MadokaTextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.85, height: 80))
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
        
        headerTap = UILongPressGestureRecognizer(target: self, action: #selector(headerTapped))
        headerTap.minimumPressDuration = 0
        headerView.addGestureRecognizer(headerTap)
    
        view.addSubview(continueButton)
        imagePicker.delegate = self
        
        doSet()

    }
    
    // called by gesture recognizer
    func headerTapped(gesture: UITapGestureRecognizer) {
        
        // handle touch down and touch up events separately
        if gesture.state == .Began {
            headerView.animateDown()
            
        } else if gesture.state == .Ended { // optional for touch up event catching
            headerView.animateUp()
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
            
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
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
        
        let pictureRequest = FBSDKGraphRequest(graphPath: "me/picture??width=720&height=720&redirect=false", parameters: nil)
        pictureRequest.startWithCompletionHandler({
            (connection, result, error: NSError!) -> Void in
            if error == nil {
                let dictionary = result as? NSDictionary
                let data = dictionary?.objectForKey("data")
                let urlPic = (data?.objectForKey("url"))! as! String
                self.headerView.imageView.loadImageUsingCacheWithURLString(urlPic, completion: {result in
                    self.smallProfileImageView.image = self.resizeImage( self.headerView.imageView.image!, newWidth: 150)
                })

            } else {
                print("\(error)")
            }
        })
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
        if let picData = UIImageJPEGRepresentation(image!, 0.9) {
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
                            let ref = FirebaseService.ref.child("users/facebook/\(self.facebook_uid)")
                            ref.setValue(user.uid)
                            let privateRef = FIRDatabase.database().reference().child("users/private/\(user.uid)")
                            privateRef.setValue([
                                "fullname":fullname
                                ], withCompletionBlock: {error, ref in
                                if error != nil {
                                    print(error?.localizedDescription)
                                }
                                else {
                                    let publicRef = FIRDatabase.database().reference().child("users/profile/\(user.uid)")
                                    publicRef.setValue([
                                        "username":username,
                                        "smallProfilePicURL": smallTaskSnapshot.metadata!.downloadURL()!.absoluteString,
                                        "largeProfilePicURL": largeTaskSnapshot.metadata!.downloadURL()!.absoluteString,
                                        "numFriends":0
                                        ], withCompletionBlock: {error, ref in
                                            if error != nil {
                                                print(error!.localizedDescription)
                                            }
                                            else {
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
