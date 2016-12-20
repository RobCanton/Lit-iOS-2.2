//
//  CameraTransition.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//



import UIKit
import QuartzCore



// MARK: Segue class
class CameraTransition: UIStoryboardSegue {
    
    
    override func perform() {
        animateSwipeDown()
        
    }
    
    
    
    private func animateSwipeDown() {
        let toViewController = destinationViewController as! CameraViewController
        let fromViewController = sourceViewController as! PopUpTabBarController
        
        let containerView = fromViewController.view.superview
        let screenBounds = fromViewController.view.bounds
        
        let cameraBtnFrame = fromViewController.cameraButton.frame
        
        let cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))

        cameraButton.frame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        cameraButton.backgroundColor = UIColor.blackColor()
        cameraButton.layer.cornerRadius = cameraBtnFrame.height/2
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        cameraButton.layer.borderWidth = fromViewController.cameraButton.layer.borderWidth
        cameraButton.tintColor = UIColor.whiteColor()

        
        let definiteBounds = UIScreen.mainScreen().bounds
        
        let recordButtonCenter = CGPoint(x: cameraButton.center.x, y: definiteBounds.height - 112)
        
        let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        color.fromValue = cameraButton.layer.borderColor
        color.toValue = UIColor.whiteColor().CGColor
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        let Width:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        Width.fromValue = cameraButton.layer.borderWidth
        Width.toValue = 4.0
        
        cameraButton.layer.borderWidth = 4.0
        
        let both:CAAnimationGroup = CAAnimationGroup()
        both.duration = 0.35
        both.animations = [color,Width]
        both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        cameraButton.layer.addAnimation(both, forKey: "color and Width")
        
        let finalToFrame = screenBounds
        let finalFromFrame = CGRectOffset(finalToFrame, 0, screenBounds.size.height)
        
        //toViewController.view.frame = CGRectOffset(finalToFrame, 0, -screenBounds.size.height)
        containerView?.insertSubview(toViewController.view, atIndex: 0)
        containerView?.addSubview(cameraButton)
        
        
        
        fromViewController.cameraButton.hidden = true
        
        
        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            //toViewController.view.frame = finalToFrame
            fromViewController.view.frame = finalFromFrame
            cameraButton.transform = CGAffineTransformMakeScale(1.3, 1.3)
            cameraButton.center = recordButtonCenter
            cameraButton.backgroundColor = UIColor.clearColor()
            }, completion: { finished in
                cameraButton.removeFromSuperview()
                toViewController.recordBtn?.hidden = false
                let fromVC = self.sourceViewController
                let toVC = self.destinationViewController
                fromVC.presentViewController(toVC, animated: false, completion: nil)
        })
    }
    
    
}

// MARK: Unwind Segue class
class CameraUnwindTransition: UIStoryboardSegue {
    
    
    override func perform() {
        animateSwipeDown()
        
    }
    
    
    private func animateSwipeDown() {
        let toViewController = destinationViewController as! PopUpTabBarController
        let fromViewController = sourceViewController as! CameraViewController
        
        
    
        let containerView = fromViewController.view.superview
        var screenBounds = fromViewController.view.bounds
        
        
        let cameraBtnFrame = toViewController.cameraButton.frame
        
        let cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        
        cameraButton.frame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        cameraButton.backgroundColor = UIColor.clearColor()
        cameraButton.layer.cornerRadius = cameraBtnFrame.height/2
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        cameraButton.layer.borderWidth = toViewController.cameraButton.layer.borderWidth
        cameraButton.tintColor = UIColor.whiteColor()
        
        cameraButton.transform = CGAffineTransformMakeScale(1.3, 1.3)
        
        let definiteBounds = UIScreen.mainScreen().bounds
        
        let recordButtonCenter = CGPoint(x: cameraButton.center.x, y: definiteBounds.height - 112)
        
        
        
        let bb = UIScreen.mainScreen().bounds
        
        let rbc = CGPoint(x: cameraButton.center.x, y: bb.height - 112)
        cameraButton.center = rbc
        
        let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        color.fromValue = cameraButton.layer.borderColor
        color.toValue = UIColor.whiteColor().CGColor
        cameraButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        let Width:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        Width.fromValue = 4.0
        Width.toValue = toViewController.cameraButton.layer.borderWidth
        
        cameraButton.layer.borderWidth = toViewController.cameraButton.layer.borderWidth
        
        let both:CAAnimationGroup = CAAnimationGroup()
        both.duration = 0.35
        both.animations = [color,Width]
        both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        cameraButton.layer.addAnimation(both, forKey: "color and Width")
        

        var yo = CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height - screenStatusBarHeight)
        let finalToFrame = CGRectOffset(yo, 0, screenStatusBarHeight)
        let finalFromFrame = CGRectOffset(finalToFrame, 0, -screenBounds.size.height)
        
        toViewController.view.frame = CGRectOffset(finalToFrame, 0, screenBounds.size.height)
        containerView?.addSubview(toViewController.view)

        let finalCameraFrame = CGRect(x: screenBounds.width/2 - cameraBtnFrame.size.width/2, y: screenBounds.height - cameraBtnFrame.height - 8, width: cameraBtnFrame.width, height: cameraBtnFrame.height)
        
        if fromViewController.recordBtn.hidden {
            cameraButton.hidden = true
        }
        
        fromViewController.recordBtn.hidden = true
        containerView?.addSubview(cameraButton)
        
        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            cameraButton.transform = CGAffineTransformIdentity
            cameraButton.frame = finalCameraFrame
            cameraButton.backgroundColor = UIColor.blackColor()
            toViewController.view.frame = finalToFrame
            fromViewController.view.alpha = 0.0
            }, completion: { finished in
                cameraButton.removeFromSuperview()
                toViewController.cameraButton.hidden = false
                let fromVC: UIViewController = self.sourceViewController
                fromVC.dismissViewControllerAnimated(false, completion: nil)

        })
    }
    
    
}