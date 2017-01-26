//
//  ContainerViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ContainerViewController:UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var conversation:Conversation?
    var partnerImage:UIImage?
    var isEmpty:Bool = false
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toMessage" {
            guard let c = conversation else { return }
            let controller = segue.destinationViewController as! ChatViewController
            controller.isEmpty = isEmpty
            controller.partnerImage = partnerImage
            controller.conversation = c
            controller.containerDelegate = self
        }
    }
}
