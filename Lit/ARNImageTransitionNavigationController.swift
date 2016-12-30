//
//  ARNImageTransitionNavigationController.swift
//  ARNZoomImageTransition
//
//  Created by xxxAIRINxxx on 2015/08/08.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit
import ARNTransitionAnimator

class ARNImageTransitionNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    weak var interactiveAnimator : ARNTransitionAnimator?
    var currentOperation : UINavigationControllerOperation = .None
    
    
    var doZoomTransition = false
        {
        didSet{
            print("doZoomTransition: \(doZoomTransition)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactivePopGestureRecognizer?.enabled = false
        self.delegate = self
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    func navigationController(navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if !doZoomTransition {
            return nil
        }
        
        self.currentOperation = operation
        
        if let _interactiveAnimator = self.interactiveAnimator {
            return _interactiveAnimator
        }
        
        if operation == .Push {
            return ARNImageZoomTransition.createAnimator(.Push, fromVC: fromVC, toVC: toVC)
        } else if operation == .Pop {
            return ARNImageZoomTransition.createAnimator(.Pop, fromVC: fromVC, toVC: toVC)
        }
        
        return  ARNImageZoomTransition.createAnimator(.None, fromVC: fromVC, toVC: toVC)
    }
    
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        if !doZoomTransition {
            return nil
        }
        
        if let _interactiveAnimator = self.interactiveAnimator {
            if  self.currentOperation == .Pop {
                return _interactiveAnimator
            }
        }
        return nil
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if let modal = viewController as? ModalViewController {
            if modal.dotings {
                doZoomTransition = true
                if let animator = modal.animatorRef {
                    interactiveAnimator = animator
                }

            } else {
                doZoomTransition = false
            }
            
        } else {
            doZoomTransition = false
        }
    }

    

}
