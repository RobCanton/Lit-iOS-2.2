//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class EditProfileViewController: UITableViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func handleCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func handleSave(sender: AnyObject) {
    }
    


}
