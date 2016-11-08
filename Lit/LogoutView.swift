//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class LogoutView: MessageView {
    
    @IBOutlet weak var contentView: UIStackView!
    
    var profileRow:DialogRow!
    var rows = [DialogRow]()
    
    var logoutHandler:(()->())?
    var cancelHandler:(()->())?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let cancelButton = UIButton()
        cancelButton.backgroundColor = UIColor.grayColor()
        cancelButton.layer.cornerRadius = 5
        cancelButton.clipsToBounds = true
        cancelButton.setTitle("cancel", forState: .Normal)
        cancelButton.tintColor = UIColor.whiteColor()
        cancelButton.titleLabel?.font = UIFont(name: "Avenir-Black", size: 20.0)
        cancelButton.addTarget(self, action: #selector(cancel), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(cancelButton)
        
        
        let logoutButton = UIButton()
        logoutButton.backgroundColor = errorColor
        logoutButton.layer.cornerRadius = 5
        logoutButton.clipsToBounds = true
        logoutButton.setTitle("log out", forState: .Normal)
        logoutButton.tintColor = UIColor.whiteColor()
        logoutButton.titleLabel?.font = UIFont(name: "Avenir-Black", size: 20.0)
        logoutButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(logoutButton)
    }
    


    
    func logout(sender:UIButton) {
        if logoutHandler != nil {
            logoutHandler!()
        }
    }
    
    func cancel(sender:UIButton) {
        if cancelHandler != nil {
            cancelHandler!()
        }
    }
    
    
    
}
