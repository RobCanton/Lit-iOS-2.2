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
        
        if operation == UINavigationControllerOperation.Push && fromVC.isKindOfClass(MainViewController) {
            let main = fromVC as! MainViewController
            let transition = main.transtition
            transition.operation = UINavigationControllerOperation.Push
            transition.duration = 0.4
            transition.selectedCellFrame = main.selectedCellFrame
            
            return transition
        }
        
        if operation == UINavigationControllerOperation.Pop && toVC.isKindOfClass(MainViewController) {
            let main = toVC as! MainViewController
            let transition = main.transtition
            transition.operation = UINavigationControllerOperation.Pop
            transition.duration = 0.4
            
            return transition
        }
        
        
        return nil
    }

}
