//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

protocol UploadSelectorDelegate {
    func send(upload:Upload)
}

class UploadSelectorView: MessageView {
    
    @IBOutlet weak var contentView: UIStackView!
    
    var profileRow:DialogRow!
    var rows = [DialogRow]()
    
    var delegate:UploadSelectorDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileRow = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow

        profileRow.setToProfileRow()
        profileRow.addTarget(self, action: #selector(rowTapped), forControlEvents: .TouchUpInside)
        contentView.addArrangedSubview(profileRow)

        
        let key = mainStore.state.userState.activeLocationKey
        for location in mainStore.state.locations {
            if location.getKey() == key {
                addLocationOption(location)
            }
        }
        
        let sendButton = UIButton()
        sendButton.backgroundColor = accentColor
        sendButton.layer.cornerRadius = 5
        sendButton.clipsToBounds = true
        sendButton.setTitle("Upload", forState: .Normal)
        sendButton.tintColor = UIColor.whiteColor()
        sendButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 18.0)
        sendButton.addTarget(self, action: #selector(send), forControlEvents: .TouchUpInside)
        
        contentView.addArrangedSubview(sendButton)
    }
    
    func addLocationOption(location:Location) {
     let row = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow
        row.setToLocationRow(location)
        row.addTarget(self, action: #selector(rowTapped), forControlEvents: .TouchUpInside)
        contentView.addArrangedSubview(row)
        rows.append(row)
    }
    
    func rowTapped(sender:DialogRow) {
        if sender.isActive {
            sender.active(false)
        } else {
            sender.active(true)
        }
    }
    
    func send(sender:UIButton) {
        sender.enabled = false
        
        let toUserProfile = profileRow.isActive
        var locationKey:String = ""
        var keys = [String]()
        for row in rows {
            if row.isActive {
                keys.append(row.key)
                locationKey = row.key
                break
            }
        }
        let upload = Upload(toUserProfile: toUserProfile, locationKey: locationKey)
        delegate?.send(upload)
        
    }
    
    

}
