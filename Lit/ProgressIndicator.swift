//
//  ProgressIndicator.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProgressIndicator: UIView {

    var progress:UIView!
    var paused = false
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        
        self.layer.cornerRadius = frame.height / 2
        self.clipsToBounds = true
        
        
        backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        
        progress = UIView()
        resetProgress()
        progress.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        addSubview(progress)
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func startAnimating(duration:Double) {
        removeAnimation()
        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.duration = duration
        animation.fromValue = progress.bounds.width
        animation.toValue = bounds.width
        animation.fillMode = kCAFillModeForwards
        animation.removedOnCompletion = false
        
        progress.layer.anchorPoint = CGPointMake(0,0.5)
        progress.layer.addAnimation(animation, forKey: "bounds")
    }
    
    func pauseAnimation() {
        if !paused {
            paused = true
            let pausedTime = progress.layer.convertTime(CACurrentMediaTime(), toLayer: nil)
            progress.layer.speed = 0.0
            progress.layer.timeOffset = pausedTime
        }
    }
    
    func removeAnimation() {
        progress.layer.removeAnimationForKey("bounds")
    }
    
    func completeAnimation() {
        removeAnimation()
        completeProgress()
    }
    
    func completeProgress() {
        progress.frame = CGRectMake(0,0,bounds.width,bounds.height)
    }
    
    func resetProgress() {
        progress.frame = CGRectMake(0,0,0,bounds.height)
    }

}
