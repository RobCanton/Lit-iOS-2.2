import Foundation
import CoreLocation

protocol GPSServiceDelegate {
    func tracingLocation(currentLocation: CLLocation)
    func tracingLocationDidFailWithError(error: NSError)
    func authorizationChange()
}

class GPSService: NSObject, CLLocationManagerDelegate {
    
    class var sharedInstance: GPSService {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            
            static var instance: GPSService? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = GPSService()
        }
        return Static.instance!
    }
    
    var locationManager: CLLocationManager?
    var lastLocation: CLLocation?
    var delegate: GPSServiceDelegate?
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined:
                print("No access")
                locationManager.requestWhenInUseAuthorization()
                break
            case .Restricted, .Denied:
                break
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                print("Access")
                break
            }
        } else {
            print("Location services are not enabled")
            locationManager.requestWhenInUseAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            // requestWhenInUseAuthorization
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // The accuracy of the location data
        locationManager.distanceFilter = 25 // The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
        locationManager.delegate = self
    }
    
    
    func isAuthorized() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined:
                self.locationManager?.requestWhenInUseAuthorization()
                return true
            case .Restricted, .Denied:
                return false
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                print("Access")
                return true
            }
        } else {
            return false
        }
    }
    
    func startUpdatingLocation() {
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        
        // singleton for get last location
        self.lastLocation = location
        
        // use for real time update location
        updateLocation(location)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        // do on error
        updateLocationDidFailWithError(error)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        delegate?.authorizationChange()
    }
    
    // Private function
    private func updateLocation(currentLocation: CLLocation){
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tracingLocation(currentLocation)
    }
    
    private func updateLocationDidFailWithError(error: NSError) {
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tracingLocationDidFailWithError(error)
    }
}