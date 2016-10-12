//
//  PostsViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-11.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ARNTransitionAnimator

class PostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ARNImageTransitionZoomable {

    let cellIdentifier = "photoCell"
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    var location:Location!
    var photos = [StoryItem]()
    var collectionView:UICollectionView?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let key = mainStore.state.viewLocationKey
        
        for _location in mainStore.state.locations {
            if _location.getKey() == key {
                location = _location
            }
        }
        
        screenSize = self.view.frame
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height-50), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "PhotoCell", bundle: nil)
        collectionView!.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.bounces = true
        
        collectionView!.backgroundColor = UIColor.blackColor()
        self.view.addSubview(collectionView!)
        
        
        let uid = mainStore.state.viewUser
        let ref = FirebaseService.ref.child("users_public/\(uid)/uploads")
        
        print(ref.description())
        var postKeys = [String]()
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.exists() {
                print("Exists")
                for child in snapshot.children {
                    print("KEY: \(child.key!!)")
                    postKeys.append(child.key!!)
                }
                self.downloadStory(postKeys)
            } else {
                print("DNE")
            }

        })
        
    }
    
    func downloadStory(postKeys:[String]) {
        FirebaseService.downloadStory(postKeys, completionHandler: { story in
            self.photos = story.reverse()
            self.collectionView!.reloadData()
        })
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
    
    func getItemSize(indexPath:NSIndexPath) -> CGSize {

        return CGSize(width: screenWidth/3, height: screenWidth/3);
    }
    
    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        print("pop down ting")
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
        controller.mode = .User
        controller.item = self.photos[self.selectedIndexPath!.item]
        let operationType: ARNTransitionAnimatorOperation = .Present
        let animator = ARNTransitionAnimator(operationType: operationType, fromVC: self.navigationController!, toVC: controller)
        
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
        self.navigationController!.presentViewController(controller, animated: true, completion: nil)
        
        
    }
    
    func createTransitionImageView() -> UIImageView {
        
        let imageView = UIImageView()
        imageView.loadImageUsingCacheWithURLString(photos[selectedIndexPath!.item].getDownloadUrl()!.absoluteString, completion: { result in})
        imageView.contentMode = self.selectedImageView!.contentMode
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = false
        let attr = collectionView!.layoutAttributesForItemAtIndexPath(selectedIndexPath!)
        let size = getItemSize(selectedIndexPath!)
        
        let v = parentViewController!.parentViewController! as! UserProfileViewController
        let parentOffset = v.scrollView.contentOffset.y
        
        let offset = collectionView!.contentOffset.y + parentOffset

        imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let imagePoint = CGPoint(x: attr!.center.x, y: attr!.center.y - offset)
        imageView.center = self.parentViewController!.view.convertPoint(imagePoint, fromView: self.view)
        
        
        
        return imageView
    }
    
    func presentationCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = true
    }
    
    func dismissalCompletionAction(completeTransition: Bool) {
        self.selectedImageView?.hidden = false
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            let v = parentViewController!.parentViewController! as! UserProfileViewController
            v.scrollView.setContentOffset(CGPointMake(0, -300), animated: true)
            v.navigationController?.setNavigationBarHidden(false, animated: true)
            scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
        }
        
        if scrollView.contentOffset.y > 0 {
            let v = parentViewController!.parentViewController! as! UserProfileViewController
            if v.scrollView.contentOffset.y == -300 {
                v.scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
                v.navigationController?.setNavigationBarHidden(true, animated: true)
                scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
            }
        }
    }
    
    


}
