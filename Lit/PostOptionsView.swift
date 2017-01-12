//
//  PostOptionsView.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-11.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import UIKit
import SwiftMessages

class PostOptionsView: MessageView {
    
    @IBOutlet weak var contentView: UIStackView!
    
    var logoutHandler:(()->())?
    var cancelHandler:(()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView.layer.cornerRadius = 0
        backgroundView.clipsToBounds = true
        
        let cancelButton = UIButton()
        cancelButton.backgroundColor = UIColor.blackColor()
        

        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.tintColor = UIColor.whiteColor()
        cancelButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 16.0)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        cancelButton.addTarget(self, action: #selector(cancel), forControlEvents: .TouchUpInside)
        cancelButton.addTarget(self, action: #selector(buttonDown), forControlEvents: .TouchDown)
        cancelButton.addTarget(self, action: #selector(buttonCanceled), forControlEvents: .TouchCancel)
        
        
        let removeButton = UIButton()
        removeButton.backgroundColor = UIColor.blackColor()
        
        removeButton.setTitle("Remove from Fiction", forState: .Normal)
        removeButton.tintColor = UIColor.whiteColor()
        removeButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 16.0)
        removeButton.titleLabel?.textColor = UIColor.blackColor()
        removeButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        removeButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
        removeButton.addTarget(self, action: #selector(buttonDown), forControlEvents: .TouchDown)
        removeButton.addTarget(self, action: #selector(buttonCanceled), forControlEvents: .TouchCancel)
        
        contentView.addArrangedSubview(removeButton)
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

