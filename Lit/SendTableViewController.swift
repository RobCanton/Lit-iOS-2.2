//
//  SendTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class SendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var sendLabel: UILabel!
    
    var upload:Upload!
    
    var sendTap:UITapGestureRecognizer!
    
    @IBAction func handleReturn(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func sent() {
        self.presentingViewController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func send() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.startAnimating()
        activityIndicator.center = sendView.center
        view.addSubview(activityIndicator)
        
        sendLabel.hidden = true
        
        
        upload.toProfile = selected["profile"] as! Bool
        upload.toStory = selected["story"] as! Bool
        upload.locationKey = selected["location"] as! String
        
        
        if let videoURL = upload.videoURL {
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let outputUrl = documentsURL.URLByAppendingPathComponent("output.mp4")
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputUrl)
            }
            catch let error as NSError {
                if error.code != 4 && error.code != 2 {
                    return print("Error \(error)")
                }
            }
            upload.videoURL = outputUrl
            FirebaseService.compressVideo(videoURL, outputURL: outputUrl, handler: { session in
                /*
                 T0D0 - HANDLE COMPRESSION ERRORS
                 */
                dispatch_async(dispatch_get_main_queue(), {
                    FirebaseService.uploadVideo(self.upload, completionHandler: { success in
                            self.sent()
                    })
                    
                })
            })
        } else if upload.image != nil {
            FirebaseService.sendImage(upload, completionHandler: { success in
                self.sent()
            })
        }
        
        
    }
    
    var activeLocations = [Location]()
    
    var selected:[String:AnyObject] = [
        "profile" : false,
        "story"   : false,
        "location": ""
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendTap = UITapGestureRecognizer(target: self, action: #selector(send))
        toggleSendView()
        
        let nib = UINib(nibName: "SendProfileViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "profileCell")
        
        let nib2 = UINib(nibName: "SendLocationViewCell", bundle: nil)
        tableView.registerNib(nib2, forCellReuseIdentifier: "locationCell")
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView.reloadData()
        
        var _activeLocations = [Location]()
        
        for location in mainStore.state.locations {
            let distance = location.getCoordinates().distanceFromLocation(upload.coordinates!) / 1000
            if distance < inRangeDistance {
                _activeLocations.append(location)
            }
        }
        
        _activeLocations.sortInPlace({
            return $0.getDistance() < $1.getDistance()
        })
        
        self.activeLocations = _activeLocations
        
        tableView.reloadData()
        
    }
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return activeLocations.count
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 64
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 1 {
            let headerView = UINib(nibName: "SendLocationHeaderView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! SendLocationHeaderView
            headerView.hidden = false
            if activeLocations.count == 0 {
                headerView.label.text = "No nearby locations."
            } else {
                headerView.label.text = "Select a nearby location."
            }
            return headerView
        }
        return nil
    }
    
    var selectedLocationIndexPath:NSIndexPath?
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileCell", forIndexPath: indexPath)
                as! SendProfileViewCell
            
            if indexPath.row == 0 {
                cell.key = "profile"
                cell.label.text = "My Profile"
                cell.subtitle.text = ""
            } else if indexPath.row == 1 {
                cell.key = "story"
                cell.label.text = "My Story"
                cell.subtitle.text = "(Lasts 24 hours)"
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileCell", forIndexPath: indexPath)
                as! SendProfileViewCell
            let location = activeLocations[indexPath.row]
            cell.key = location.getKey()
            cell.label.text = location.getName()
            if let dist = location.getDistance() {
                cell.subtitle.text = "\(getDistanceString(dist)) away"
            }
            return cell
        }
        
    }
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 {
            if let oldIndexPath = selectedLocationIndexPath {
                selectedLocationIndexPath = indexPath
                if oldIndexPath.row != indexPath.row {
                    let oldCell = tableView.cellForRowAtIndexPath(oldIndexPath) as! SendProfileViewCell
                    oldCell.toggleSelection()
                    if oldCell.isActive {
                        selected["location"] = oldCell.key
                    } else {
                        selected["location"] = ""
                    }
                } else {
                    selectedLocationIndexPath = nil
                }
            } else {
                selectedLocationIndexPath = indexPath
            }
            
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! SendProfileViewCell
            
            cell.toggleSelection()
            if cell.isActive {
                selected["location"] = cell.key
            } else {
                selected["location"] = ""
            }
            
        } else {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! SendProfileViewCell
            
            cell.toggleSelection()
            if cell.isActive {
                selected[cell.key] = true
            } else {
                selected[cell.key] = false
            }
        }
        
        toggleSendView()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func toggleSendView() {
        if hasSelection() {
            sendView.backgroundColor = accentColor
            sendLabel.textColor = UIColor.whiteColor()
            sendView.userInteractionEnabled = true
            sendView.addGestureRecognizer(sendTap)
            
        } else {
            
            sendView.backgroundColor = UIColor(white: 0.03, alpha: 1.0)
            sendLabel.textColor = UIColor.darkGrayColor()
            sendView.userInteractionEnabled = false
            sendView.removeGestureRecognizer(sendTap)
        }
    }
    
    func hasSelection() -> Bool {
        let location = selected["location"] as! String
        if location != "" {
            return true
        } else {
            let toProfile = selected["profile"] as! Bool
            let toStory   = selected["story"] as! Bool
            
            if toProfile || toStory {
                return true
            }
        }
        
        return false
    }
    
    

}
