//
//  DummyViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class DummyViewController:UIViewController, UITabBarControllerDelegate, UINavigationControllerDelegate
{
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {

        if viewController.isKindOfClass(StoriesViewController) {
            print("willShowViewController")
            let vc = viewController as! StoriesViewController
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

        }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(StoriesViewController) {
            print("didShowViewController")
            let vc = viewController as! StoriesViewController
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController!.delegate = self;
        self.navigationController?.delegate
        
    }
    
    
    
}