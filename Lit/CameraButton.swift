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
    
    var redCircle:UIView!
    var interactionView:UIView!
    
    var tappedHandler:(()->())?
    var pressedHandler:((state:UIGestureRecognizerState)->())?


    override init(frame:CGRect) {
        super.init(frame:frame)

        
        ring = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        ring.backgroundColor = UIColor.clearColor()
        ring.layer.cornerRadius = ring.frame.height/2
        ring.layer.borderColor = UIColor.whiteColor().CGColor
        ring.layer.borderWidth = 4.0
        ring.clipsToBounds = true
        ring.layer.masksToBounds = true
        ring.tintColor = UIColor.whiteColor()
        ring.userInteractionEnabled = true
        ring.transform = CGAffineTransformMakeScale(1.3, 1.3)
        ring.center = CGPointMake(self.frame.width / 2, self.frame.height/2)
        ring.applyShadow(1, opacity: 0.25, height: 1, shouldRasterize: false)
        self.userInteractionEnabled = true

        let pMargin:CGFloat = 8.5
        let pFrame = CGRect(x: ring.frame.origin.x - pMargin, y: ring.frame.origin.y - pMargin, width: ring.frame.width + pMargin * 2, height: ring.frame.height + pMargin * 2)
        progresser = KDCircularProgress(frame: pFrame)
        progresser.startAngle = -90
        progresser.progressThickness = 0.275
        progresser.trackThickness = 0.2
        progresser.trackColor = UIColor.clearColor()
        progresser.clockwise = true
        progresser.glowAmount = 0.0

        progresser.roundedCorners = false

        progresser.angle = 0
        progresser.setColors(UIColor(colorLiteralRed: 205/255, green: 0, blue: 0, alpha: 1.0))
        
        progresser.layer.addSublayer(ring.layer)
        progresser.layer.mask = ring.layer
        progresser.layer.masksToBounds = true
        
        redCircle = UIView(frame: frame)
        redCircle.layer.cornerRadius = redCircle.frame.width/2
        redCircle.clipsToBounds = true
        redCircle.backgroundColor = UIColor(colorLiteralRed: 205/255, green: 0, blue: 0, alpha: 1.0)
        redCircle.transform = CGAffineTransformMakeScale(0, 0)
        
        interactionView = UIView(frame: frame)
        interactionView.layer.cornerRadius = interactionView.frame.width/2
        interactionView.clipsToBounds = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        interactionView.addGestureRecognizer(tap)

        press = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
        press.minimumPressDuration = 0.5
        interactionView.addGestureRecognizer(press)
        interactionView.userInteractionEnabled = true
        
        addSubview(redCircle)
        addSubview(ring)
        addSubview(progresser)
        addSubview(interactionView)

    }
    
    func tapped(sender:UITapGestureRecognizer) {
        tappedHandler?()
        
        UIView.animateWithDuration(0.25, animations: {
            self.ring.alpha = 0.4
            }
            , completion: { result in
                self.ring.alpha = 1.0
        })
    }
    
    func pressed(sender: UILongPressGestureRecognizer)
    {
        let state = sender.state
        pressedHandler?(state: state)
        switch state {
        case .Began:
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.CurveEaseInOut], animations: {
                self.ring.alpha = 0.20
                self.redCircle.transform = CGAffineTransformMakeScale(0.5, 0.5)
                self.transform = CGAffineTransformMakeScale(1.3, 1.3)
            }, completion: { result in })
            break
        case .Ended:
            break
        default:
            break
        }
        
        // animate
    }
    
    func updateProgress(progress:CGFloat) {
        progresser.angle = 360.0 * Double(progress)
        
    }
    
    func resetProgress() {
        progresser.angle = 0
        UIView.animateWithDuration(0.05, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.ring.alpha = 1.0
            self.redCircle.transform = CGAffineTransformMakeScale(0, 0)
            self.transform = CGAffineTransformMakeScale(1, 1)
            }, completion: { result in })

    }
    
    
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }


}
