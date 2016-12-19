//
//  DismissAnimator.swift
//  InteractiveModal
//
//  Created by Robert Chen on 1/8/16.
//  Copyright © 2016 Thorn Technologies. All rights reserved.
//

import UIKit

class DismissAnimator : NSObject {
}

class Interactor: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

extension DismissAnimator : UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.20
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let containerView = transitionContext.containerView()
            else {
                return
        }
        
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        let screenBounds = UIScreen.mainScreen().bounds
        let bottomLeftCorner = CGPoint(x: 0, y: screenBounds.height)
        let finalFrame = CGRect(origin: bottomLeftCorner, size: screenBounds.size)
        
//        UIView.animateWithDuration(
//            transitionDuration(transitionContext),
//            animations: {
//                fromVC.view.frame = finalFrame
//            },
//            completion: { _ in
//                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
//            }
//        )
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            fromVC.view.frame = finalFrame
            },
                                   completion: { _ in
                                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
}