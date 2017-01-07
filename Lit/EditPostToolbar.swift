//
//  EditPostToolbar.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-03.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class EditPostToolbar: UIView {

    var deleteHandler:(()->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    @IBAction func handleDelete(sender: AnyObject) {
        deleteHandler?()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
