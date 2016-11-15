//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class ProfilePictureMessageView: MessageView {
    
    @IBOutlet weak var contentView: UIStackView!
    
    var facebookHandler:(()->())?
    var libraryHandler:(()->())?
    var cancelHandler:(()->())?
    
    @IBOutlet weak var blurBG: UIVisualEffectView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        blurBG.layer.cornerRadius = 5
        blurBG.clipsToBounds = true
        
        let facebookButton = UIButton()
        //facebookButton.backgroundColor = accentColor
        facebookButton.layer.cornerRadius = 5
        facebookButton.clipsToBounds = true
        facebookButton.setTitle("Import from Facebook", forState: .Normal)
        facebookButton.titleLabel?.font = UIFont(name: "Avenir-Medium", size: 18.0)
        facebookButton.setTitleColor(accentColor, forState: .Normal)
        facebookButton.setTitleColor(accentFadeColor, forState: .Highlighted)
        facebookButton.addTarget(self, action: #selector(facebook), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(facebookButton)
        
        let libraryButton = UIButton()
        //libraryButton.backgroundColor = accentColor
        libraryButton.layer.cornerRadius = 5
        libraryButton.clipsToBounds = true
        libraryButton.setTitle("Choose from Library", forState: .Normal)
        libraryButton.titleLabel?.font = UIFont(name: "Avenir-Medium", size: 18.0)
        libraryButton.setTitleColor(accentColor, forState: .Normal)
        libraryButton.setTitleColor(accentFadeColor, forState: .Highlighted)
        libraryButton.addTarget(self, action: #selector(library), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(libraryButton)
        
        let cancelButton = UIButton()
        //cancelButton.backgroundColor = UIColor.grayColor()
        cancelButton.layer.cornerRadius = 5
        cancelButton.clipsToBounds = true
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.titleLabel?.font = UIFont(name: "Avenir-Medium", size: 18.0)
        cancelButton.setTitleColor(accentColor, forState: .Normal)
        cancelButton.setTitleColor(accentFadeColor, forState: .Highlighted)
        cancelButton.addTarget(self, action: #selector(cancel), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(cancelButton)
    }
    
    func facebook(sender:UIButton) {
        facebookHandler?()
    }
    
    func library(sender:UIButton) {
        libraryHandler?()
    }
    
    func cancel(sender:UIButton) {
        cancelHandler?()
    }
}
