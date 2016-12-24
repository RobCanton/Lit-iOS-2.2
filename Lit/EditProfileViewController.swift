//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class BioTableViewCell: UITableViewCell {
    
    
    
}

class EditProfileViewController: UITableViewController {

    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var bioPlaceholder: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 240 // Something reasonable to help ios render your cells
        
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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    @IBAction func handleCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func handleSave(sender: AnyObject) {
        
        var basicProfileObj = [String:AnyObject]()
        var username = ""
        if let _username = usernameTextField.text { username = _username }
        
        basicProfileObj["username"] = username
        if let name = nameTextField.text {
            basicProfileObj["name"] = name
        }

        let uid = mainStore.state.userState.uid
        let basicProfileRef = FirebaseService.ref.child("users/profile/basic/\(uid)")
        basicProfileRef.updateChildValues(basicProfileObj, withCompletionBlock: { error in
        
            let fullProfileRef = FirebaseService.ref.child("users/profile/full/\(uid)")
            var fullProfileObj = [String:AnyObject]()
            
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
                FirebaseService.getUserFullProfile(user, completionHandler: { _fullUser in
                    if let fullUser = _fullUser {
                        mainStore.dispatch(UserIsAuthenticated(user: fullUser))
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
            }
        })
    }
}

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        
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
    
//    func textViewDidBeginEditing(textView: UITextView) {
//        switch textView {
//        case bioTextView:
//            bioPlaceholder.hidden = true
//            break
//        default:
//            break
//        }
//    }
//    
//    func textViewDidEndEditing(textView: UITextView) {
//        switch textView {
//        case bioTextView:
//            bioPlaceholder.hidden = !textView.text.isEmpty
//            break
//        default:
//            break
//        }
//    }
}

extension EditProfileViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == usernameTextField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > 16 { return false }
            
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
        return true
    }
    
    func textViewChanged(){
        usernameTextField.text = usernameTextField.text?.lowercaseString;
    }
    
    
}
