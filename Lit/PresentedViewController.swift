//
//  PresentedViewController.swift
//  CustomTransition
//
//  Created by naru on 2016/07/27.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit


class PresentedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    var tabBarRef:PopUpTabBarController!
    var authorOverlay: PostAuthorView?
    var photos = [StoryItem]()
    var photoIndex:Int!
    {
        didSet {
            label!.text = photos[photoIndex].getKey()
            authorOverlay?.setPostMetadata(photos[photoIndex])
            authorOverlay?.authorTappedHandler = { user in
                self.navigationController?.delegate = self
                let controller = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewControllerWithIdentifier("UserProfileViewController") as! UserProfileViewController
                controller.user = user
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    var label:UILabel!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
        setTings()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        tabBarRef.setTabBarVisible(false, animated: true)
        setTings()
    }
    func setTings() {
        
//        var rect = self.view.frame
//        print("WE SET TINGS \(rect.origin.y)")
//        rect.origin.y = 0
//        self.view.frame = rect
    
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        tabBarRef.setTabBarVisible(true, animated: true)
        
    }
    

    var collectionView:UICollectionView!
    
    
    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews")
        setTings()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        setTings()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        //self.navigationItem.titleView = self.titleLabel
        self.navigationItem.leftBarButtonItem = backItem
        self.view.backgroundColor = UIColor.greenColor()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = UIScreen.mainScreen().bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        collectionView.registerClass(PresentedCollectionViewCell.self, forCellWithReuseIdentifier: "presented_cell")
        collectionView.backgroundColor = UIColor.redColor()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        collectionView.opaque = true
        self.view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = true
        collectionView.autoresizingMask = [UIViewAutoresizing.FlexibleTopMargin]
//        
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        //self.view.addSubview(self.closeButton)
//        
//        let equal = NSLayoutRelation.Equal
//        let top = NSLayoutAttribute.Top
//        let lm = NSLayoutAttribute.LeadingMargin
//        let none = NSLayoutAttribute.NotAnAttribute
//        let topConstraint = NSLayoutConstraint(item: collectionView, attribute: top, relatedBy: equal, toItem: view, attribute: lm, multiplier: 1, constant: 0)
//        
//        NSLayoutConstraint.activateConstraints([topConstraint])
        label = UILabel(frame: CGRectMake(0,0,self.view.frame.width,100))
        label.textColor = UIColor.whiteColor()
        label.center = view.center
        label.textAlignment = .Center
        self.view.addSubview(label)
        
        let overlayMargin:CGFloat = 4.0
        authorOverlay = UINib(nibName: "PostAuthorView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! PostAuthorView
        authorOverlay!.frame = CGRect(x: overlayMargin, y: view.frame.height - authorOverlay!.frame.height - overlayMargin, width: view.frame.width, height: authorOverlay!.frame.height)
        view.addSubview(authorOverlay!)
        
        authorOverlay!.translatesAutoresizingMaskIntoConstraints = true
        authorOverlay!.autoresizingMask = [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleTopMargin]
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return UIScreen.mainScreen().bounds.size
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        setTings()
        self.navigationController?.delegate = transitionController
        
        if let gestureRecognizers = self.view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                    panGestureRecognizer.delegate = self
                }
            }
        }
        if authorOverlay != nil {
            print(authorOverlay!.frame)
            print(authorOverlay!.alpha)
            print(authorOverlay!.center)
        }
    }
    
    
    
    // MARK: Elements
    
    weak var transitionController: TransitionController!
    
//    lazy var collectionView: UICollectionView = {
//        
//        
//    }()
    
    
    lazy var backItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: #selector(onBackItemClicked(_:)))
        item.tintColor = UIColor.whiteColor()
        return item
    }()
    
    lazy var userItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "User", style: .Plain, target: self, action: #selector(onUserItemClicked(_:)))
        item.tintColor = UIColor.whiteColor()
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
        cell.contentView.backgroundColor = UIColor.blueColor()
        let item = photos[indexPath.item]
        cell.content.loadImageUsingCacheWithURLString(item.getDownloadUrl()!.absoluteString, completion: { loaded in
        })
        
        return cell
    }
    
    
    func onBackItemClicked(sender: AnyObject) {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }
    func onUserItemClicked(sender: AnyObject) {
        
        self.navigationController?.delegate = self
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewControllerWithIdentifier("DummyViewController")
        //controller.user = user
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Gesture Delegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let indexPath: NSIndexPath = self.collectionView.indexPathsForVisibleItems().first!
        self.transitionController.userInfo = ["destinationIndexPath": indexPath, "initialIndexPath": indexPath]
        
        let panGestureRecognizer: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translate: CGPoint = panGestureRecognizer.translationInView(self.view)
        return Double(abs(translate.y)/abs(translate.x)) > M_PI_4
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        let xOffset = scrollView.contentOffset.x
//        let ratio = xOffset / collectionView.frame.width
//        let iRatio = ratio - CGFloat(photoIndex)
//        if iRatio < -0.5 {
//            if photoIndex > 0 {
//                photoIndex = photoIndex - 1
//            }
//        } else if iRatio > 0.5 {
//            if photoIndex < photos.count - 1 {
//                photoIndex = photoIndex + 1
//            }
//        }
//        
//        let absRatio = abs(iRatio)
//        let r = max(0, 1 - absRatio * 2)
//        label.alpha = r
//        authorOverlay?.alpha = r
//        print("index: \(photoIndex) | iRatio: \(r)")
//    }
    
}

extension PresentedViewController: View2ViewTransitionPresented {
    
    func destinationFrame(userInfo: [String: AnyObject]?, isPresenting: Bool) -> CGRect {
        
        let indexPath: NSIndexPath = userInfo!["destinationIndexPath"] as! NSIndexPath
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
            photoIndex = indexPath.item
            
            let contentOfffset: CGPoint = CGPoint(x: self.collectionView.frame.size.width*CGFloat(indexPath.item), y: 0.0)
            self.collectionView.contentOffset = contentOfffset
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
        view.backgroundColor = UIColor.yellowColor()
        view.clipsToBounds = true
        view.contentMode = .ScaleAspectFill
        return view
    }()
}