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
    
    var statusBarBG:UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurView.frame = statusBarBG.bounds
        statusBarBG.addSubview(blurView)
        
        view.addSubview(statusBarBG)
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
