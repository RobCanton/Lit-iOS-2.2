//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class TacoDialogView: MessageView {


    
    @IBOutlet weak var contentView: UIStackView!
    
    var profileRow:DialogRow!
    var rows = [DialogRow]()
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileRow = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow
        profileRow.tag = 0
        profileRow.setToProfileRow()
        profileRow.addTarget(self, action: #selector(rowTapped), forControlEvents: .TouchUpInside)
        contentView.addArrangedSubview(profileRow)
        rows.append(profileRow)
        
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
        sendButton.setTitle("send", forState: .Normal)
        sendButton.tintColor = UIColor.whiteColor()
        sendButton.titleLabel?.font = UIFont(name: "Avenir-Black", size: 20.0)
        
        contentView.addArrangedSubview(sendButton)
    }
    
    func addLocationOption(location:Location) {
     let row = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow
        row.tag = rows.count
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
    
    

}
