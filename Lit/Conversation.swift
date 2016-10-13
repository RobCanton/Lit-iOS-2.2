//
//  Conversation.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//


import Foundation

protocol GetUserProtocol {
    func userLoaded(user:User)
}

class Conversation {
    
    private var key:String
    private var partner_uid:String
    private var partner:User?
    
    var delegate:GetUserProtocol?
    
    init(key:String, partner_uid:String)
    {
        self.key         = key
        self.partner_uid = partner_uid
        retrieveUser()
    }
    
    func getKey() -> String {
        return key
    }
    
    func getPartnerId() -> String {
        return partner_uid
    }
    
    func getPartner() -> User? {
        return partner
    }
    
    
    func retrieveUser() {
        FirebaseService.getUser(partner_uid, completionHandler: { _user in
            if let user = _user {
                self.partner = user
                self.delegate?.userLoaded(self.partner!)
            }
        })
    }

}