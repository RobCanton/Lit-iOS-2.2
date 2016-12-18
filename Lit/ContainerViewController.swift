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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toMessage" {
            guard let c = conversation else { return }
            let controller = segue.destinationViewController as! ChatViewController
            controller.conversation = c
            controller.containerDelegate = self
        }
    }
}
