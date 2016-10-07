//
//  RatingViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-17.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import ReSwift

enum RatingState {
    case Selection, CheckedIn, NotHere
}

class RatingViewController: UIViewController, StoreSubscriber  {

    @IBOutlet weak var locationTitle: UILabel!
    
    @IBOutlet weak var visitorsCountLabel: UILabel!
    @IBOutlet weak var friendsCountLabel: UILabel!
    
    @IBOutlet weak var imageContainer: UIView!
    
    var voteState: RatingState = .Selection {
        didSet {
            switch voteState {
            case .Selection:
                checkInBtn.layer.borderColor = accentColor.CGColor
                checkInBtn.layer.borderWidth = 2.0
                notHereBtn.layer.borderColor = UIColor.whiteColor().CGColor
                notHereBtn.layer.borderWidth = 2.0
                break
            case .CheckedIn:
                checkInBtn.enabled = false
                notHereBtn.enabled = false
                checkInBtn.setTitle("CHECKED IN", forState: .Normal)
                checkInBtn.layer.borderWidth = 0
                checkInBtn.backgroundColor = accentColor
                checkInBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
                notHereBtn.layer.borderColor = UIColor.grayColor().CGColor
                notHereBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
                break
            case .NotHere:
                checkInBtn.enabled = false
                notHereBtn.enabled = false
                checkInBtn.layer.borderColor = UIColor.grayColor().CGColor
                checkInBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
                notHereBtn.layer.borderWidth = 0
                notHereBtn.backgroundColor = UIColor.whiteColor()
                notHereBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
                break
            }
        }
    }
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.frame = imageContainer.bounds
        imageContainer.addSubview(imageView)

        imageView.contentMode = .ScaleAspectFill
        imageView.layer.cornerRadius = 4;
        imageView.clipsToBounds = true;
        //imageView.layer.borderWidth = 2.0
        //imageView.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).CGColor
        
        
        imageContainer.layer.masksToBounds = false
        imageContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        imageContainer.layer.shadowOpacity = 0.4
        imageContainer.layer.shadowRadius = 2
        
//        checkInBtn.layer.cornerRadius = 4
//        notHereBtn.layer.cornerRadius = 4
        
        checkInBtn.layer.masksToBounds = false
        checkInBtn.layer.shadowOffset = CGSize(width: 0, height: 4)
        checkInBtn.layer.shadowOpacity = 0.4
        checkInBtn.layer.shadowRadius = 2
        
        notHereBtn.layer.masksToBounds = false
        notHereBtn.layer.shadowOffset = CGSize(width: 0, height: 4)
        notHereBtn.layer.shadowOpacity = 0.4
        notHereBtn.layer.shadowRadius = 2

        // Do any additional setup after loading the view.
    }
    
    var activeLocation: Location?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        let key = mainStore.state.userState.activeLocationKey
        print("RatingViewController: New Active Location")
        for location in mainStore.state.locations {
            if key == location.getKey() {
                setLocation(location)
            }
        }
        
        voteState = mainStore.state.userState.vote
    }
    
    func setLocation(location:Location) {
        activeLocation = location
        //locationTitle.styleLocationTitle(location.getName())
        
        locationTitle.styleLocationTitleWithPreText("you are at\n\(activeLocation!.getName().lowercaseString)", size1: 28, size2: 18)

        imageView.alpha = 0
        imageView.loadImageUsingFileWithURLString(activeLocation!, completion: { result in
            if result {
                UIView.animateWithDuration(1.0, animations: {
                    self.imageView.alpha = 1.0
                })
            } else {
                self.imageView.alpha = 1
            }
        })
        activeLocation!.collectInfo()
        let visitorsCount = activeLocation!.getVisitors().count
        let friendsCount = activeLocation!.getFriendsCount()

        visitorsCountLabel.styleVisitorsCountLabel(visitorsCount, size: 22)
        friendsCountLabel.styleFriendsCountLabel(friendsCount, size: 22, you: false)
        
        
    }
    
    @IBOutlet weak var checkInBtn: UIButton!
    @IBOutlet weak var notHereBtn: UIButton!
    
    
    @IBAction func checkInTapped(sender: UIButton) {
        let uid = mainStore.state.userState.uid
        let city = mainStore.state.userState.activeCity!.getKey()
        let location = mainStore.state.userState.activeLocationKey
        let ref = FirebaseService.ref.child("locations/\(city)/\(location)")
        ref.child("visitors/\(uid)").setValue(true)
        
        let userRef = FirebaseService.ref.child("users_public/\(uid)/visits")
        userRef.child("\(city)/\(location)").setValue([".sv": "timestamp"])
    }
    
    @IBAction func notHereTapped(sender: UIButton) {
        //mainStore.dispatch(Vote(state: .CheckedIn))
        let uid = mainStore.state.userState.uid
        let city = mainStore.state.userState.activeCity!.getKey()
        let location = mainStore.state.userState.activeLocationKey
        let ref = FirebaseService.ref.child("users_public/\(uid)/ignores")
        ref.child("\(city)/\(location)").setValue([".sv": "timestamp"])
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let uid = mainStore.state.userState.uid
        let city = mainStore.state.userState.activeCity!.getKey()
        let location = mainStore.state.userState.activeLocationKey
        let ref = FirebaseService.ref.child("users_public/\(uid)")
        
        ref.child("visits/\(city)/\(location)").observeEventType(.Value, withBlock: { (snapshot) in
            if snapshot.exists() {
                mainStore.dispatch(Vote(state: .CheckedIn))
            }
        })

        
        ref.child("ignores/\(city)/\(location)").observeEventType(.Value, withBlock: { (snapshot) in
            if snapshot.exists() {
                mainStore.dispatch(Vote(state: .NotHere))
            }
        })
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
