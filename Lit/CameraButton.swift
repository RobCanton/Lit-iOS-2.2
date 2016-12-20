//
//  CameraButton.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class CameraButton: UIView {
    
    var tap:UITapGestureRecognizer!
    var press:UILongPressGestureRecognizer!
    var ring:UIButton!
    
    var progresser:KDCircularProgress!
    
    var tappedHandler:(()->())?
    var pressedHandler:((state:UIGestureRecognizerState)->())?


    override init(frame:CGRect) {
        super.init(frame:frame)
        self.frame = frame
        self.backgroundColor = UIColor.clearColor()
        
        ring = UIButton(frame: frame)
        ring.backgroundColor = UIColor.clearColor()
        ring.layer.cornerRadius = ring.frame.height/2
        ring.layer.borderColor = UIColor.whiteColor().CGColor
        ring.layer.borderWidth = 4.0
        ring.tintColor = UIColor.whiteColor()
        ring.userInteractionEnabled = true
        self.userInteractionEnabled = true
        
        addSubview(ring)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        ring.addGestureRecognizer(tap)
        
        press = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
        press.minimumPressDuration = 0.75
        ring.addGestureRecognizer(press)
        

        progresser = KDCircularProgress(frame: frame)
        progresser.startAngle = -90
        progresser.progressThickness = 0.25
        progresser.trackThickness = 0.2
        progresser.trackColor = UIColor.clearColor()
        progresser.clockwise = true
        progresser.glowAmount = 0.0

        progresser.roundedCorners = true

        progresser.angle = 140
        progresser.setColors(UIColor.redColor())
        addSubview(progresser)
    
    }
    
    func tapped(sender:UITapGestureRecognizer) {
        tappedHandler?()
        
        UIView.animateWithDuration(0.15, animations: {
            self.ring.alpha = 0.4
            }
            , completion: { result in
                self.ring.alpha = 1.0
        })
    }
    
    func pressed(sender: UILongPressGestureRecognizer)
    {
        pressedHandler?(state: sender.state)
        
        // animate
    }
    
    
    
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }


}
