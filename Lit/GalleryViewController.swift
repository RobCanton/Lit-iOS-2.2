// MXWebViewController.swift
//
// Copyright (c) 2015 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import ARNTransitionAnimator

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ARNImageTransitionZoomable {
    
    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!

    var location:Location!
    var photos = [StoryItem]()

    var collectionView:UICollectionView?
    override func viewDidLoad() {
        super.viewDidLoad()
        let key = mainStore.state.viewLocationKey
        
        for _location in mainStore.state.locations {
            if _location.getKey() == key {
                location = _location
            }
        }
        
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        collectionView!.dataSource = self
        collectionView!.delegate = self

        collectionView!.backgroundColor = UIColor.blackColor()
        self.view.addSubview(collectionView!)

        
        FirebaseService.downloadStory(location.getPostKeys(), completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
        



    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        
        cell.setPhoto(photos[indexPath.item])
        
        return cell
    }

    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return getItemSize(indexPath)
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCell
        selectedImageView = cell.imageView
        selectedIndexPath = indexPath
        
        showInteractive()
        
    }
    
    
    var selectedImageView : UIImageView?
    var selectedIndexPath: NSIndexPath?
    
    var animator : ARNTransitionAnimator?
    
    
    func showInteractive() {
        let storyboard = UIStoryboard(name: "ModalViewController", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        controller.item = self.photos[self.selectedIndexPath!.item]
        let operationType: ARNTransitionAnimatorOperation = .Present
        let animator = ARNTransitionAnimator(operationType: operationType, fromVC: self, toVC: controller)
        
        animator.presentationBeforeHandler = { [weak self] containerView, transitionContext in
            containerView.addSubview(controller.view)

            
            controller.view.layoutIfNeeded()
            
            let sourceImageView = self!.createTransitionImageView()
            let destinationImageView = controller.createTransitionImageView()
            
            containerView.addSubview(sourceImageView)
            
            controller.presentationBeforeAction()
            
            controller.view.alpha = 0.0
            
            animator.presentationAnimationHandler = { containerView, percentComplete in
                sourceImageView.frame = destinationImageView.frame
                
                controller.view.alpha = 1.0
            }
            
            animator.presentationCompletionHandler = { containerView, completeTransition in
                sourceImageView.removeFromSuperview()
                self!.presentationCompletionAction(completeTransition)
                controller.presentationCompletionAction(completeTransition)
            }
        }
        
        animator.dismissalBeforeHandler = { [weak self] containerView, transitionContext in
            
            let fromVC = transitionContext.viewForKey(UITransitionContextFromViewKey)
            if case .Dismiss = self!.animator!.interactiveType {
                containerView.addSubview(fromVC!)
            } else {
                containerView.addSubview(self!.view)
            }
            containerView.bringSubviewToFront(controller.view)
            
            let sourceImageView = controller.createTransitionImageView()
            let destinationImageView = self!.createTransitionImageView()
            containerView.addSubview(sourceImageView)
            
            let sourceFrame = sourceImageView.frame;
            let destFrame = destinationImageView.frame;
            
            controller.dismissalBeforeAction()
            
            animator.dismissalCancelAnimationHandler = { (containerView: UIView) in
                sourceImageView.frame = sourceFrame
                controller.view.alpha = 1.0
            }
            
            animator.dismissalAnimationHandler = { containerView, percentComplete in
                if percentComplete < -0.05 { return }
                let frame = CGRectMake(
                    destFrame.origin.x - (destFrame.origin.x - sourceFrame.origin.x) * (1 - percentComplete),
                    destFrame.origin.y - (destFrame.origin.y - sourceFrame.origin.y) * (1 - percentComplete),
                    destFrame.size.width + (sourceFrame.size.width - destFrame.size.width) * (1 - percentComplete),
                    destFrame.size.height + (sourceFrame.size.height - destFrame.size.height) * (1 - percentComplete)
                )
                sourceImageView.frame = frame
                controller.view.alpha = 1.0 - (1.0 * percentComplete)
            }
            
            animator.dismissalCompletionHandler = { containerView, completeTransition in
                
                self!.dismissalCompletionAction(completeTransition)
                controller.dismissalCompletionAction(completeTransition)
                sourceImageView.removeFromSuperview()
            }
        }
        
        
        self.animator = animator
        
        self.animator!.interactiveType = .Dismiss
        controller.transitioningDelegate = self.animator
        self.presentViewController(controller, animated: true, completion: nil)
        
        
    }
    
    
    
    func createTransitionImageView() -> UIImageView {
        
        let imageView = UIImageView()
        imageView.loadImageUsingCacheWithURLString(photos[selectedIndexPath!.item].getDownloadUrl()!.absoluteString, completion: { result in})
        imageView.contentMode = self.selectedImageView!.contentMode
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = false
        let attr = collectionView?.layoutAttributesForItemAtIndexPath(selectedIndexPath!)
        let size = getItemSize(selectedIndexPath!)
        imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        imageView.center = self.parentViewController!.view.convertPoint(attr!.center, fromView: self.view)
        
        
        
        return imageView
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = false
    }

    func getItemSize(indexPath:NSIndexPath) -> CGSize {
        if photos.count == 1 {
            return CGSize(width: screenWidth, height: screenWidth);
        }
        else if photos.count < 6 {
            if indexPath.item == 0 {
                return CGSize(width: screenWidth, height: screenWidth/2);
            }
            return CGSize(width: screenWidth/2, height: screenWidth/2);
        }
        
        if indexPath.item == 0 {
            return CGSize(width: screenWidth, height: screenWidth/3);
        }
        
        return CGSize(width: screenWidth/3, height: screenWidth/3);
    }


}





