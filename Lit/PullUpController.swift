//
//  PullUpController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ISHPullUp


protocol StoryPullUpProtocol {
    func setCurrentItem(item:StoryItem)
}

class BottomVC: UIViewController, StoryPullUpProtocol {
    weak var pullUpController: ISHPullUpViewController!
    
    @IBOutlet weak var topView: UIView!
    
    var bottomHeight:CGFloat = 0.0
    
    var author:User?
    
    private var halfWayPoint = CGFloat(0)
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
        pullUpController.snapThreshold = 0.35

        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        topView.addGestureRecognizer(tapGesture)
        
        pullUpController.setState(.Collapsed, animated: true)
    
    }
    
    func handleTapGesture(gesture: UITapGestureRecognizer) {
        pullUpController.toggleStateAnimated(true)
    }
    
    let descriptions = [
        "So many things to say here. Like really i dont know what else I can say. There is so good stuff in this message. Like really tho its good stuff.",
        "Haha check this out everyone",
        "I realize the Swift book provided an implementation of a random number generator. Is the best practice to copy and paste this implementation in one's own program? Or is there a library that does this that we can use now? I realize the Swift book provided an implementation of a random number generator.",
        "Good stuff!",
        "A lotta of things to say here but i just eventually got this job but i have to tell you the weirdest thign!"
    ]
    
    var item:StoryItem?
    
    func setCurrentItem(item:StoryItem) {
        
        if self.item == nil || item.getKey() != self.item!.getKey() {
            self.item = item
            let number = randomInt(0, max: descriptions.count - 1)
            let description = descriptions[number]
            descriptionLabel.text = description
            descriptionLabel.sizeToFit()
            pullUpController.invalidateLayout()
            pullUpController.setState(.Collapsed, animated: false)
            
            FirebaseService.getUser(item.authorId, completionHandler: { user in
                if user != nil {
                    self.setAuthorInfo(user!)
                }
            })
        }
        
        
    }
    
    func setAuthorInfo(user:User) {
        author = user
        
        
        
    }
    
    
    
}

func randomInt(min: Int, max:Int) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}

extension BottomVC: ISHPullUpSizingDelegate, ISHPullUpStateDelegate {
    func pullUpViewController(pullUpViewController: ISHPullUpViewController, minimumHeightForBottomViewController bottomVC: UIViewController) -> CGFloat {
        return topView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height //topView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height;
    }
    
    func pullUpViewController(pullUpViewController: ISHPullUpViewController, maximumHeightForBottomViewController bottomVC: UIViewController, maximumAvailableHeight: CGFloat) -> CGFloat {
        halfWayPoint = maximumAvailableHeight * 0.92 / 2.0
        return maximumAvailableHeight * 0.92
    }
    
    func pullUpViewController(pullUpViewController: ISHPullUpViewController, targetHeightForBottomViewController bottomVC: UIViewController, fromCurrentHeight height: CGFloat) -> CGFloat {
        // if around 30pt of the half way point -> snap to it
        if abs(height - halfWayPoint) < halfWayPoint / 2 {
            return halfWayPoint
        }
        
        // default behaviour
        return height
    }
    
    func pullUpViewController(pullUpViewController: ISHPullUpViewController, updateEdgeInsets edgeInsets: UIEdgeInsets, forBottomViewController contentVC: UIViewController) {
        
    }
    
    func pullUpViewController(pullUpViewController: ISHPullUpViewController, didChangeToState state: ISHPullUpState) {
        switch state {
        case .Collapsed:
            playStory()
            break
        case .Intermediate:
            pauseStory()
            break
        case .Dragging:
            pauseStory()
            break
        case .Expanded:
            pauseStory()
            break
        }
    }
    
    private func textForState(state: ISHPullUpState) -> String {
        switch state {
        case .Collapsed:
            playStory()
            return "Collapsed"
        case .Intermediate:
            pauseStory()
            return "Intermediate"
        case .Dragging:
            pauseStory()
            return "Dragging"
        case .Expanded:
            pauseStory()
            return "Expanded"
        }
    }
    
    func pauseStory() {
        if let controller = pullUpController.contentViewController as? StoriesController {
           controller.getCurrentCell()?.pauseStory()
        }
    }
    
    func playStory() {
        if let controller = pullUpController.contentViewController as? StoriesController {
            controller.getCurrentCell()?.resumeStory()
        }
    }
}






class WrapperController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var transitionController: TransitionController!
    var tabBarRef:PopUpTabBarController!
    var statusBarShouldHide = false
    var pullUpController:PullUpController!
    
    var stories:[UserStory]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.brownColor()
        
        pullUpController = PullUpController()
        pullUpController.parent = self
        pullUpController.contentVC.userStories = stories
        pullUpController.view.bounds = self.view.bounds
        pullUpController.willMoveToParentViewController(self)
        self.view.addSubview(pullUpController.view)
        pullUpController.didMoveToParentViewController(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarRef.setTabBarVisible(false, animated: true)
        //
                UIView.animateWithDuration(0.15, animations: {
                    self.statusBarShouldHide = true
                    self.setNeedsStatusBarAppearanceUpdate()
                })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarRef.setTabBarVisible(false, animated: false)
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.delegate = transitionController

        pullUpController.contentVC.playCurrentCell()
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                }
            }
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabBarRef.setTabBarVisible(true, animated: true)
        clearDirectory("temp")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return statusBarShouldHide
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return !CGRectContainsPoint(pullUpController.bottomVC.view.bounds, touch.locationInView(pullUpController.bottomVC.view))
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {

        let indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)//self.collectionView.indexPathsForVisibleItems().first!
        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        
        
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4 && translate.y > 0
    }
    
    func popStoryController(animated:Bool) {
//        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
//        let initialPath = self.transitionController.userInfo!["initialIndexPath"] as! NSIndexPath
//        self.transitionController.userInfo!["destinationIndexPath"] = indexPath
//        self.transitionController.userInfo!["initialIndexPath"] = NSIndexPath(forItem: indexPath.item, inSection: initialPath.section)
        navigationController?.popViewControllerAnimated(animated)
    }
}

extension WrapperController: View2ViewTransitionPresented {

    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        return view.frame
    }

    func destinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {

        return view

    }

    func prepareDestinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) {

        if isPresenting {

        }
    }
}


class PullUpController: ISHPullUpViewController, UIGestureRecognizerDelegate {
    
    var parent:WrapperController!
    var tabBarRef:PopUpTabBarController!
    var statusBarShouldHide = false
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    var bottomVC:BottomVC!
    var contentVC:StoriesController!
    
    private func commonInit() {
        snapThreshold = 1.0
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        bottomVC = storyBoard.instantiateViewControllerWithIdentifier("bottom") as! BottomVC
        contentVC = StoriesController()
        contentVC.delegate = bottomVC
        contentViewController = contentVC
        bottomViewController = bottomVC
        contentVC.pullUpController = self
        bottomVC.pullUpController = self
        //contentDelegate = contentVC
        sizingDelegate = bottomVC
        stateDelegate = bottomVC
    }
}
//
//
//extension PullUpController: View2ViewTransitionPresented {
//    
//    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
//        return view.frame
//    }
//    
//    func destinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
//        
////        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
////        let cell: StoryViewController = self.collectionView.cellForItemAtIndexPath(indexPath) as! StoryViewController
////        
////        cell.prepareForTransition(isPresenting)
//        
//        return view
//        
//    }
//    
//    func prepareDestinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) {
//        
//        if isPresenting {
//            
////            let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
////            currentIndex = indexPath
////            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
////            self.collectionView.contentOffset = contentOffset
////            self.collectionView.reloadData()
////            self.collectionView.layoutIfNeeded()
//        }
//    }
//    
//    
//    
//    
//}

