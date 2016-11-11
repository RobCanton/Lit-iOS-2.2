//
//  ActiveLocationView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import SwiftMessages

class ActiveLocationView: MessageView {

    
    @IBOutlet weak var locationTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleLocationTitle("You are near\nsame nightclub", size: 20.0)
        
    }
    
    func styleLocationTitle(_str:String, size: CGFloat) {
        let str = _str.lowercaseString
        let font = UIFont(name: "Avenir-Black", size: size)
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        

            
        let a1: [String: AnyObject] = [
            NSFontAttributeName : UIFont(name: "Avenir-Light", size: 11.0)!,
            ]
            
        title.addAttributes(a1, range: NSRange(location: 0, length: 12))
        
        let searchStrings = ["the ", " the ", " & ", "nightclub", " nightclub ", "club", " club"]
        for string in searchStrings {
            if let range = str.rangeOfString(string) {
                
                let index: Int = str.startIndex.distanceTo(range.startIndex)
                
                let a2: [String: AnyObject] = [
                    NSFontAttributeName : UIFont(name: "Avenir-Light", size: size)!,
                    ]
                
                title.addAttributes(a2, range: NSRange(location: index, length: string.characters.count))
            }
        }
        
        locationTitle.attributedText = title
    }
    

}