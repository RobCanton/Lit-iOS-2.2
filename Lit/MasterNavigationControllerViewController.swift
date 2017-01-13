//
//  MasterNavigationController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-14.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import UIKit
class MasterNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        
        
        
        return nil
    }
    
}