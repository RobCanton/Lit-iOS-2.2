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
        cancelButton.backgroundColor = UIColor.blackColor()

        cancelButton.layer.borderColor = UIColor.whiteColor().CGColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.tintColor = UIColor.whiteColor()
        cancelButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 16.0)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        cancelButton.addTarget(self, action: #selector(cancel), forControlEvents: .TouchUpInside)
        cancelButton.addTarget(self, action: #selector(buttonDown), forControlEvents: .TouchDown)
        cancelButton.addTarget(self, action: #selector(buttonCanceled), forControlEvents: .TouchCancel)
        

        let logoutButton = UIButton()
        logoutButton.backgroundColor = UIColor.whiteColor()
        
        logoutButton.layer.borderColor = UIColor.whiteColor().CGColor
        logoutButton.layer.borderWidth = 1.0
        logoutButton.setTitle("Log Out", forState: .Normal)
        logoutButton.tintColor = UIColor.blackColor()
        logoutButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 16.0)
        logoutButton.titleLabel?.textColor = UIColor.blackColor()
        logoutButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        logoutButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
        logoutButton.addTarget(self, action: #selector(buttonDown), forControlEvents: .TouchDown)
        logoutButton.addTarget(self, action: #selector(buttonCanceled), forControlEvents: .TouchCancel)
        
        contentView.addArrangedSubview(logoutButton)
        contentView.addArrangedSubview(cancelButton)
    }
    
    func buttonDown(sender:UIButton) {
        sender.alpha = 0.5
    }
    
    func buttonCanceled(sender:UIButton) {
        sender.alpha = 1.0
    }
    

        
    func logout(sender:UIButton) {
        sender.alpha = 1.0
        logoutHandler?()
    }
    
    func cancel(sender:UIButton) {
        sender.alpha = 1.0
        cancelHandler?()
    }
}
