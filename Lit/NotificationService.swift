import Foundation
import CoreLocation

protocol NotificationDelegate {
    func messageRecieved(sender:String, message:String)
    func newFollower(uid:String)
    func changeTab(index:Int)
}

class NotificationService: NSObject {
    
    class var sharedInstance: NotificationService {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            
            static var instance: NotificationService? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = NotificationService()
        }
        return Static.instance!
    }

    var delegate:NotificationDelegate?
    
    override init() {
        super.init()
        
    }
    
    var messageNotifcationsEnabled = true
    func messageReceived(sender:String, message:String) {
        if messageNotifcationsEnabled {
            delegate?.messageRecieved(sender, message: message)
        }
    }
    
    func newFollower(uid:String) {
        delegate?.newFollower(uid)
    }
    
    func changeTab(index:Int) {
        delegate?.changeTab(index)
    }
    
    
}