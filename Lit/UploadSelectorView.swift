//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages
import MapKit
import CoreLocation

protocol UploadSelectorDelegate {
    func send(upload:Upload)
}

class UploadSelectorView: MessageView, MKMapViewDelegate {
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var contentView: UIStackView!
    
    var profileRow:DialogRow!
    
    var rows = [DialogRow]()
    
    var sendButton:UIButton!
    
    var delegate:UploadSelectorDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileRow = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow

        profileRow.setToProfileRow()
        profileRow.addTarget(self, action: #selector(rowTapped), forControlEvents: .TouchUpInside)
        contentView.addArrangedSubview(profileRow)

        
        let key = mainStore.state.userState.activeLocationKey
        for location in mainStore.state.locations {
            if location.getKey() == key {
                addLocationOption(location)
            }
        }
        
        sendButton = UIButton()
        sendButton.layer.cornerRadius = 5
        sendButton.clipsToBounds = true
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.tintColor = UIColor.whiteColor()
        sendButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 18.0)
        sendButton.addTarget(self, action: #selector(doSend), forControlEvents: .TouchUpInside)
        sendButton.enabled = false
        deactivateSendButton()
        
        contentView.addArrangedSubview(sendButton)

        mapView.layer.cornerRadius = 5
        mapView.clipsToBounds = true
        
        mapView.delegate = self
        mapView.showsUserLocation = false
        mapView.showsCompass = false
        mapView.showsBuildings = true
        mapView.pitchEnabled = true
        mapView.userInteractionEnabled = false

    }
    
    
    
    var largeOverlay:MKCircle!
    var smallOverlay:MKCircle!
    func setCoordinate(coordinate:CLLocation) {
        
        let regionRadius = 100.0
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
        
        largeOverlay = MKCircle(centerCoordinate: coordinate.coordinate, radius: 64.0)
        mapView.addOverlay(largeOverlay)
        
        smallOverlay = MKCircle(centerCoordinate: coordinate.coordinate, radius: 12.0)
        mapView.addOverlay(smallOverlay)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay === largeOverlay {
            // draw the track
            
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor(red: 0, green: 128/255, blue: 255, alpha: 0.3)
            
            return circleRenderer
        }
        
        if overlay === smallOverlay {
            // draw the track
            
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor(red: 0, green: 128/255, blue: 255, alpha: 1.0)
            circleRenderer.strokeColor = UIColor.whiteColor()
            circleRenderer.lineWidth = 2.0
            
            return circleRenderer
        }
        
        return MKCircleRenderer()
    }

    
    func addLocationOption(location:Location) {
     let row = UINib(nibName: "DialogRow", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! DialogRow
        row.setToLocationRow(location)
        row.addTarget(self, action: #selector(rowTapped), forControlEvents: .TouchUpInside)
        contentView.addArrangedSubview(row)
        rows.append(row)
    }
    
    func rowTapped(sender:DialogRow) {
        if sender.isActive {
            sender.active(false)
        } else {
            sender.active(true)
        }
        
        var hasSelection = false
        if profileRow.isActive {
            hasSelection = true
        } else {
            
            for row in rows {
                if row.isActive {
                    hasSelection = true
                }
            }
        }
        
        if hasSelection {
            activateSendButton()
        } else {
            deactivateSendButton()
        }
    }
    
    func activateSendButton() {
        sendButton.backgroundColor = accentColor
        sendButton.enabled = true
    }
    
    func deactivateSendButton() {
        sendButton.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        sendButton.enabled = false
    }
    
    func doSend(sender:UIButton) {
        sender.enabled = false
        
        let toUserProfile = profileRow.isActive
        var locationKey:String = ""
        var keys = [String]()
        for row in rows {
            if row.isActive {
                keys.append(row.key)
                locationKey = row.key
                break
            }
        }
        let upload = Upload(toUserProfile: toUserProfile, locationKey: locationKey)
        delegate?.send(upload)
        
    }
    
    

}
