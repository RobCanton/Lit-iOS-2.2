//
//  LeftTransition.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class LeftTransition: NSObject ,UIViewControllerAnimatedTransitioning {
    var dismiss = false
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning){
        // Get the two view controllers
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let containerView = transitionContext.containerView()!
        
        var originRect = containerView.bounds
        originRect.origin = CGPointMake(CGRectGetWidth(originRect), 0)
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        if dismiss{
            containerView.bringSubviewToFront(fromVC.view)
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                fromVC.view.frame = originRect
                }, completion: { (_ ) -> Void in
                    fromVC.view.removeFromSuperview()
                    transitionContext.completeTransition(true )
            })
            
        }else{
            toVC.view.frame = originRect
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                                        toVC.view.center = containerView.center
            }) { (_) -> Void in
                fromVC.view.removeFromSuperview()
                transitionContext.completeTransition(true )
            }
        }
    }
}