//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol EditProfileProtocol {
    func getFullUser()
}

class EditProfileViewController: UITableViewController {

    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var bioPlaceholder: UITextField!
    
    var headerView: EditProfilePictureView!
    
    var profileImageChanged = false
    
    var didEdit = false
    
    var smallImageURL:String?
    var largeImageURL:String?
    
    let imagePicker = UIImagePickerController()
    
    var delegate:EditProfileProtocol?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let user = mainStore.state.userState.user {
            if let largeImage = user.largeImageURL {
                if !profileImageChanged {
                    headerView.setImage(largeImage)
                    headerView.handler = showProfilePhotoMessagesView
                }
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = UINib(nibName: "EditProfilePictureView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! EditProfilePictureView
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 275)
        headerView.userInteractionEnabled = true
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 275 // Something reasonable to help ios render your cells
        
        
        
        tableView.tableHeaderView = headerView
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textViewChanged), forControlEvents: .EditingChanged);
        
        usernameTextField.delegate = self
        usernameTextField.addTarget(self, action: #selector(textViewChanged), forControlEvents: .EditingChanged);
        
        if let user = mainStore.state.userState.user {
            
            nameTextField.text     = user.getName()
            usernameTextField.text = user.getDisplayName()
            
            if let bio = user.bio {
                bioTextView.text = bio
            }
            
        }
        
        bioTextView.delegate = self
        bioPlaceholder.hidden = !bioTextView.text.isEmpty
        
        imagePicker.delegate = self
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.barTintColor = .blackColor()
        imagePicker.navigationBar.tintColor = .whiteColor() // Cancel button ~ any UITabBarButton items
        imagePicker.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ] // Title colorr

    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    @IBAction func handleCancel(sender: AnyObject) {
        
        if didEdit {
            let cancelAlert = UIAlertController(title: "Unsaved Changes", message: "You have unsaved changes. Are you sure you want to cancel?", preferredStyle: UIAlertControllerStyle.Alert)
            
            cancelAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            cancelAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            presentViewController(cancelAlert, animated: true, completion: nil)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func handleSave(sender: AnyObject) {
        
        cancelButton.enabled = false
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: .Normal)
        headerView.userInteractionEnabled = false
        nameTextField.enabled = false
        bioTextView.userInteractionEnabled = false
        title = "Saving..."
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButtonItem(barButton, animated: true)
        activityIndicator.startAnimating()
        
        if profileImageChanged {
            let image = headerView.imageView.image!
            let largeImage = resizeImage(image, newWidth: 720)
            let smallImage = resizeImage(image, newWidth: 150)
            
            UserService.uploadProfilePicture(largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
                if success {
                    self.smallImageURL = smallImageURL
                    self.largeImageURL = largeImageURL
                    UserService.updateProfilePictureURL(largeImageURL!, smallURL: smallImageURL!, completionHandler: {
                        self.updateUser()
                    })
                }
            })
            
        } else {
            updateUser()
        }
        
    }
    
    func updateUser() {
        var basicProfileObj = [String:AnyObject]()
        
        if let name = nameTextField.text {
            basicProfileObj["name"] = name
        }
        
        if let smallURL = smallImageURL {
            basicProfileObj["profileImageURL"] = smallURL
        }

        let uid = mainStore.state.userState.uid
        let basicProfileRef = FirebaseService.ref.child("users/profile/basic/\(uid)")
        basicProfileRef.updateChildValues(basicProfileObj, withCompletionBlock: { error in
            
            let fullProfileRef = FirebaseService.ref.child("users/profile/full/\(uid)")
            var fullProfileObj = [String:AnyObject]()
            
            if let largeURL = self.largeImageURL {
                basicProfileObj["largeProfileImageURL"] = largeURL
            }
            
            if let bio = self.bioTextView.text {
                fullProfileObj["bio"] = bio
            } else {
                fullProfileRef.child("bio").removeValue()
            }
            
            fullProfileRef.updateChildValues(fullProfileObj, withCompletionBlock: { error in
                self.retrieveUpdatedUser()
            })
        })
    }
    
    func retrieveUpdatedUser() {
        let uid = mainStore.state.userState.uid
        
        FirebaseService.dataCache.removeObjectForKey("user-\(uid)")
        FirebaseService.getUser(uid, completionHandler: { _user in
            if let user = _user {
                FirebaseService.getUserFullProfile(user, completionHandler: { fullUser in
                    mainStore.dispatch(UserIsAuthenticated(user: fullUser))
                    self.dismissViewControllerAnimated(true, completion: {
                        self.delegate?.getFullUser()
                    })
                })
            }
        })
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            previewNewImage(pickedImage)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setFacebookProfilePicture() {
        FacebookGraph.getProfilePicture({ imageURL in
            if imageURL != nil {
                loadImageUsingCacheWithURL(imageURL!, completion: { image, fromCache in
                    if image != nil {
                       self.previewNewImage(image!)
                    }
                })
                
            }
        })
    }
    
    func previewNewImage(image:UIImage) {
        
        dispatch_async(dispatch_get_main_queue(), {
            self.didEdit = true
            self.profileImageChanged = true
            self.headerView.imageView.image = image
        })

    }
    
    func uploadProfileImages(largeImage:UIImage, smallImage:UIImage) {
        UserService.uploadProfilePicture(largeImage, smallImage: smallImage, completionHandler: { success, largeImageURL, smallImageURL in
            if success {
                UserService.updateProfilePictureURL(largeImageURL!, smallURL: smallImageURL!, completionHandler: {
                    mainStore.dispatch(UpdateProfileImageURL(largeImageURL: largeImageURL!, smallImageURL: smallImageURL!))
                    self.headerView.imageView.loadImageUsingCacheWithURLString(largeImageURL!, completion: {result in})
                })
            }
        })
    }
    
    
    
    func showProfilePhotoMessagesView() {
        usernameTextField.resignFirstResponder()
        bioTextView.resignFirstResponder()
        
     let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheet.addAction(cancelActionButton)
        
        let facebookActionButton: UIAlertAction = UIAlertAction(title: "Import from Facebook", style: .Default)
        { action -> Void in
            self.setFacebookProfilePicture()
        }
        actionSheet.addAction(facebookActionButton)
        
        let libraryActionButton: UIAlertAction = UIAlertAction(title: "Choose from Library", style: .Default)
        { action -> Void in
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        actionSheet.addAction(libraryActionButton)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
}

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        didEdit = true
        switch textView {
        case bioTextView:
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
            bioPlaceholder.hidden = !textView.text.isEmpty
            break
        default:
            break
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

}

extension EditProfileViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == usernameTextField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length

            if newLength > usernameLengthLimit { return false }
            
            // Create an `NSCharacterSet` set
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
        } else if textField === nameTextField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > 50 { return false }
            
            // Create an `NSCharacterSet`
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
    
    func textViewChanged(){
        didEdit = true
        //usernameTextField.text = usernameTextField.text?.lowercaseString;
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true;
    }
    
    
}
