//
//  DummyViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class DummyViewController:UIViewController, UITabBarControllerDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController!.delegate = self;
        
    }
    
    
    
}