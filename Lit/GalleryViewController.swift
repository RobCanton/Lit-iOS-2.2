//
//  GalleryViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//


import UIKit

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    
    var photos = [StoryItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .None
        
        self.navigationItem.leftBarButtonItem = self.backItem
        
        self.view.backgroundColor = UIColor.blackColor()
        
        self.view.addSubview(self.collectionView)
    }
    
    var tabBarRef:PopUpTabBarController!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarRef.setTabBarVisible(false, animated: true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        UIView.animateWithDuration(0.15, animations: {
            self.statusBarShouldHide = true
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
        tabBarRef.setTabBarVisible(true, animated: true)
    }
    
    // MARK: Elements
    
    weak var transitionController: TransitionController!
    
    lazy var collectionView: UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = self.view.bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        
        let collectionView: UICollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.registerClass(PresentedCollectionViewCell.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        return collectionView
    }()
    


    
    lazy var backItem: UIBarButtonItem = {
        let item: UIBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: self, action: #selector(onBackItemClicked(_:)))
        return item
    }()
    

    
    
    // MARK: CollectionView Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: PresentedCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("presented_cell", forIndexPath: indexPath) as! PresentedCollectionViewCell
        cell.contentView.backgroundColor = UIColor.blackColor()
        let item = photos[indexPath.item]
        loadImageUsingCacheWithURL(item.getDownloadUrl().absoluteString, completion: { image, fromCache in
            cell.content.image = image
        })
        
        return cell
    }
    
    // MARK: Actions
    
    func onCloseButtonClicked(sender: AnyObject) {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onBackItemClicked(sender: AnyObject) {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }
    
    func onPushItemClicked(sender: AnyObject) {
        
        self.navigationController?.delegate = self
    }
    
    // MARK: Gesture Delegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4
    }
    
    var statusBarShouldHide = false
    override func prefersStatusBarHidden() -> Bool {
        return statusBarShouldHide
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }

}

extension GalleryViewController: View2ViewTransitionPresented {
    
    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
        print("DEST PATH: \(indexPath)")
        let cell: PresentedCollectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath) as! PresentedCollectionViewCell
        return cell.content.frame
    }
    
    func destinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) -> UIView {
        
        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
        let cell: PresentedCollectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath) as! PresentedCollectionViewCell
        return cell.content
    }
    
    func prepareDestinationView(userInfo: [String: AnyObject]?, isPresenting: Bool) {
        
        if isPresenting {
            
            let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
            
            let contentOffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOffset
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}

public class PresentedCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.content)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var content: UIImageView = {
        let margin: CGFloat = 2.0
        let width: CGFloat = (UIScreen.mainScreen().bounds.size.width)
        let height: CGFloat = (UIScreen.mainScreen().bounds.size.height)
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        let view: UIImageView = UIImageView(frame: frame)
        view.backgroundColor = UIColor.blackColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
}

