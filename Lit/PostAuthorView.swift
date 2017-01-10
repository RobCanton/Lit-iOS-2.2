//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import QuartzCore

class PostAuthorView: UIView {

    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorUsernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var user:User?
    var authorTap:UITapGestureRecognizer!
    var authorTappedHandler:((user:User)->())?

    var locationTap:UITapGestureRecognizer!
    var locationTappedHandler:((location:Location)->())?
    
    var location:Location?

    
    var margin:CGFloat = 16
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        authorImageView.layer.cornerRadius = authorImageView.frame.width/2
        authorImageView.clipsToBounds = true
        authorTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        
        locationTap = UITapGestureRecognizer(target: self, action: #selector(locationTapped))
        
        let frame = CGRectMake(0, 0, authorImageView.frame.width + margin, authorImageView.frame.height + margin)
        addCircle(frame)
        
        self.applyShadow(2.0, opacity: 0.25, height: 1, shouldRasterize: false)
    }
    
    func setPostMetadata(post:StoryItem) {
        
        FirebaseService.getUser(post.getAuthorId(), completionHandler: { user in
            if user != nil {
                self.authorImageView.loadImageUsingCacheWithURLString(user!.getImageUrl(), completion: { result in })
                self.authorUsernameLabel.text = user!.getDisplayName()
                self.authorImageView.removeGestureRecognizer(self.authorTap)
                self.authorImageView.addGestureRecognizer(self.authorTap)
                
                let superView = self.authorImageView.superview!
                superView.userInteractionEnabled = true
                superView.removeGestureRecognizer(self.authorTap)
                superView.addGestureRecognizer(self.authorTap)
                
                let locSuperview = self.locationLabel.superview!
                locSuperview.userInteractionEnabled = true
                locSuperview.removeGestureRecognizer(self.locationTap)
                locSuperview.addGestureRecognizer(self.locationTap)

                self.user = user
                self.timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
                for location in mainStore.state.locations {
                    if location.getKey() == post.getLocationKey() {
                        self.location = location
                        self.locationLabel.text = location.getName()
                    }
                }
            }
        })

    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if user != nil {
            authorTappedHandler?(user: user!)
        }
    }
    
    func locationTapped(gesture:UITapGestureRecognizer) {
        if location != nil {
           locationTappedHandler?(location: location!)
        }
    }
    
    let circle = UIView();
    var progressCircle: CAShapeLayer!
    
    func addCircle(frame:CGRect) {
        circle.bounds = frame;
        circle.frame = frame;
        
        circle.layoutIfNeeded()
        
        progressCircle = CAShapeLayer();
        
        let centerPoint = CGPoint (x: circle.bounds.width / 2, y: circle.bounds.width / 2);
        let circleRadius : CGFloat = circle.bounds.width / 2 * 0.83;
        
        var circlePath = UIBezierPath(arcCenter: centerPoint, radius: circleRadius, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true    );
        
        progressCircle = CAShapeLayer ();
        progressCircle.path = circlePath.CGPath;
        progressCircle.strokeColor = UIColor.whiteColor().CGColor
        progressCircle.fillColor = UIColor.clearColor().CGColor;
        progressCircle.lineWidth = 2.0;
        progressCircle.strokeStart = 0.0;
        progressCircle.strokeEnd = 0.0;
        
        
        circle.layer.addSublayer(progressCircle);
        


        insertSubview(circle, atIndex: 0)
        //animateCircle()
        
    }
    func animateCircle() {
        let fromValue = 0.00000000001
        let toValue = 1
        let strokeEnd: CGFloat = 1.0
        let aniKey = "animateCircle"
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = 5.0
        
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = fromValue
        animation.toValue = toValue
        
        // Do a linear animation (i.e. the speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // right value when the animation ends.
        progressCircle.strokeEnd = strokeEnd
        
        // Do the actual animation
        progressCircle.addAnimation(animation, forKey: aniKey)
        circle.hidden = false
    }
    
    
}
