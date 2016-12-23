////
////  SwiftyExpandingTransition.swift
////  SwiftyExpandingCells
////
////  Created by Fischer, Justin on 11/19/15.
////  Copyright © 2015 Fischer, Justin. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//class SwiftyExpandingTransition: NSObject, UIViewControllerAnimatedTransitioning {
//    
//    var operation: UINavigationControllerOperation?
//    
//    var imageViewTop: UIImageView?
//    var imageViewBottom: UIImageView?
//    var duration: NSTimeInterval = 0
//    var selectedCellFrame = CGRectZero
//    
//    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
//        return self.duration
//    }
//    
//    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
//        let sourceVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
//        let sourceView = sourceVC.view
//        
//        let destinationVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
//        let destinationView = destinationVC.view
//        
//        let container = transitionContext.containerView()!
//        
//        let initialFrame = transitionContext.initialFrameForViewController(sourceVC)
//        let finalFrame = transitionContext.finalFrameForViewController(destinationVC)
//        
//        // must set final frame, because it could be (0.0, 64.0, 768.0, 960.0)
//        // and the destinationView frame could be (0 0; 768 1024)
//        destinationView.frame = finalFrame
//        
//        self.selectedCellFrame = CGRectMake(self.selectedCellFrame.origin.x, self.selectedCellFrame.origin.y + self.selectedCellFrame.height, self.selectedCellFrame.width, self.selectedCellFrame.height)
//        
//        var snapShot = UIImage()
//        let bounds = CGRectMake(0, 0, sourceView.bounds.size.width, sourceView.bounds.size.height)
//        
//        if self.operation == UINavigationControllerOperation.Push {
//            UIGraphicsBeginImageContextWithOptions(sourceView.bounds.size, true, 0)
//            
//            sourceView.drawViewHierarchyInRect(bounds, afterScreenUpdates: false)
//            
//            snapShot = UIGraphicsGetImageFromCurrentImageContext()
//            
//            UIGraphicsEndImageContext()
//            
//            let tempImageRef = snapShot.CGImage!
//            let imageSize = snapShot.size
//            let imageScale = snapShot.scale
//            
//            let midPoint = bounds.height / 2
//            
//            let selectedFrame = self.selectedCellFrame.origin.y - (self.selectedCellFrame.height / 2)
//            
//            let padding = self.selectedCellFrame.height * imageScale
//            print("IMG: \(imageScale) PADDING: \(padding)")
//            var topHeight: CGFloat = 0.0
//            var bottomHeight: CGFloat = 0.0
//            
//            topHeight = self.selectedCellFrame.origin.y * imageScale
//            bottomHeight = (imageSize.height - self.selectedCellFrame.origin.y) * imageScale
//            
//            let topImageRect = CGRectMake(0, 0, imageSize.width * imageScale, topHeight)
//            
//            let bottomImageRect = CGRectMake(0, topHeight, imageSize.width * imageScale, bottomHeight)
//            
//            let topImageRef = CGImageCreateWithImageInRect(tempImageRef, topImageRect)!
//            let bottomImageRef = CGImageCreateWithImageInRect(tempImageRef, bottomImageRect)
//            
//            self.imageViewTop = UIImageView(image: UIImage(CGImage: topImageRef, scale: snapShot.scale, orientation: UIImageOrientation.Up))
//            
//            if (bottomImageRef != nil) {
//                self.imageViewBottom = UIImageView(image: UIImage(CGImage: bottomImageRef!, scale: snapShot.scale, orientation: UIImageOrientation.Up))
//            }
//        }
//        
//        var startFrameTop = self.imageViewTop!.frame
//        var endFrameTop = startFrameTop
//        var startFrameBottom = self.imageViewBottom!.frame
//        var endFrameBottom = startFrameBottom
//        // include any offset if view controllers are not initially at 0 y position
//        let yOffset = self.operation == UINavigationControllerOperation.Pop ? finalFrame.origin.y : initialFrame.origin.y
//        
//        if self.operation == UINavigationControllerOperation.Pop {
//            startFrameTop.origin.y = -startFrameTop.size.height + yOffset
//            endFrameTop.origin.y = yOffset
//            startFrameBottom.origin.y = startFrameTop.height + startFrameBottom.height + yOffset
//            endFrameBottom.origin.y = startFrameTop.height + yOffset
//        } else {
//            startFrameTop.origin.y = yOffset
//            endFrameTop.origin.y = -startFrameTop.size.height + yOffset
//            startFrameBottom.origin.y = startFrameTop.size.height + yOffset
//            endFrameBottom.origin.y = startFrameTop.height + startFrameBottom.height + yOffset
//        }
//        
//        self.imageViewTop!.frame = startFrameTop
//        self.imageViewBottom!.frame = startFrameBottom
//        
//        destinationView.alpha = 0
//        sourceView.alpha = 0
//        
//        let backgroundView = UIView(frame: bounds)
//        backgroundView.backgroundColor = UIColor.blackColor()
//        
//        if self.operation == UINavigationControllerOperation.Pop {
//            sourceView.alpha = 1
//            
//            container.addSubview(backgroundView)
//            container.addSubview(sourceView)
//            container.addSubview(destinationView)
//            //container.addSubview(self.imageViewTop!)
//            container.addSubview(self.imageViewBottom!)
//            
//            if let s = sourceVC as? LocViewController {
//                if s.tableView?.contentOffset.y > 0 {
//                    s.tableView?.userInteractionEnabled = false
//                    s.scrollEndHandler = {
//                        let fadeCover = UIView(frame: endFrameBottom)
//                        fadeCover.backgroundColor = UIColor.blackColor()
//                        fadeCover.alpha = 0.0
//                        container.addSubview(fadeCover)
//                        container.bringSubviewToFront(self.imageViewBottom!)
//                        UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
//                            self.imageViewBottom!.frame = endFrameBottom
//                            fadeCover.alpha = 1.0
//                            
//                            }, completion: { (finish) -> Void in
//                                self.imageViewTop!.removeFromSuperview()
//                                self.imageViewBottom!.removeFromSuperview()
//                                fadeCover.removeFromSuperview()
//                                destinationView.alpha = 1
//                                transitionContext.completeTransition(true)
//                                s.scrollEndHandler = nil
//                        })
//                    }
//                    
//                    s.tableView?.setContentOffset(CGPointMake(0,0), animated: true)
//                } else {
//                    let fadeCover = UIView(frame: endFrameBottom)
//                    fadeCover.backgroundColor = UIColor.blackColor()
//                    fadeCover.alpha = 0.0
//                    container.addSubview(fadeCover)
//                    container.bringSubviewToFront(imageViewBottom!)
//                    UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
//                        self.imageViewBottom!.frame = endFrameBottom
//                        fadeCover.alpha = 1.0
//                        
//                        }, completion: { (finish) -> Void in
//                            self.imageViewTop!.removeFromSuperview()
//                            self.imageViewBottom!.removeFromSuperview()
//                            fadeCover.removeFromSuperview()
//                            destinationView.alpha = 1
//                            
//                            transitionContext.completeTransition(true)
//                            s.scrollEndHandler = nil
//                    })
//                }
//                
//                
//            }
//            
//            
//            
//        } else {
//            container.addSubview(backgroundView)
//            container.addSubview(destinationView)
//            container.addSubview(self.imageViewTop!)
//            container.addSubview(self.imageViewBottom!)
//            destinationView.alpha = 0
//            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
//                self.imageViewBottom!.frame = endFrameBottom
//                
//                destinationView.alpha = 1
//                
//                }, completion: { (finish) -> Void in
//                    self.imageViewTop!.removeFromSuperview()
//                    self.imageViewBottom!.removeFromSuperview()
//                    destinationView.frame = finalFrame
//                    transitionContext.completeTransition(true)
//            })
//        }
//    }
//}
