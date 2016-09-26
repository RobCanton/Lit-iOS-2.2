//
//  StoryProgressIndicator.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit



class StoryProgressIndicator: UIView {
    
    var progressBars = [UIProgressView]()
    var totalLength: Double = 0
    var currentProgress: Double = 0
    var x: CGFloat = 0
    
    let gap: CGFloat = 3.0
    
    var story:[StoryItem]!
    var activeBarIndex = 0
    
    
    func createProgressIndicator(story:[StoryItem]) {
        if story.count > 0 {
            self.story = story
            let totalWidth = self.frame.width
            let gapWidth = CGFloat(self.story.count - 1) * gap
            
            let widthMinusGap = totalWidth - gapWidth
            
            for item in story {
                totalLength += item.getLength()!
            }
            
            for i in 0 ... story.count - 1 {
                let item = story[i]
                let barWidth = CGFloat((item.getLength()! / totalLength)) * widthMinusGap
                let frame = CGRect(x: x, y: CGFloat(0), width: barWidth, height: 2.0)
                let bar = UIProgressView(frame: frame)
                bar.progressTintColor = accentColor
                bar.trackTintColor = UIColor(white: 1.0, alpha: 0.25)
                bar.progress = 0
                progressBars.append(bar)
                self.addSubview(bar)
                
                x += barWidth + gap
            }
        }
    }
    
    func activateIndicator(item:Int) {
        if item >= 0 && item < story.count {
            self.progressBars[item].progressTintColor = accentColor
            self.progressBars[item].trackTintColor = UIColor(white: 1.0, alpha: 0.5)
                
            dispatch_async(dispatch_get_main_queue(), {
                UIView.animateWithDuration(self.story[item].getLength()!, delay: 0.0, options: .CurveLinear, animations: { () -> Void in
                    self.progressBars[item].progressTintColor = accentColor
                    self.progressBars[item].trackTintColor = UIColor(white: 1.0, alpha: 0.5)
                    self.progressBars[item].setProgress(1.0, animated: true)
                    }, completion: { result in
                })
            })
        }
    }
    
    func deactivateIndicator(item:Int) {
        if item >= 0 && item < story.count {
            print("Stop animation for \(activeBarIndex)")
            progressBars[item].trackTintColor = accentColor
        }
    }
    

}