//
//  LoginService.swift
//  DropChat
//
//  Created by Eric Smith on 12/16/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

class LoginService: NSObject {
    
    func register(fbid:String, email:String, name:String, profile_image:String, callback: (NSDictionary) -> ()) {
        var info:NSDictionary!
        
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            callback(info)
            return
        }

        Alamofire.manager.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/register.php",
            parameters: ["fbid":fbid, "email":email, "name":name, "profile_image":profile_image, "token":TokenCache.sharedManager.tokenCache]
            )
            .responseJSON{ (request, response, JSON, error) in
                if (JSON != nil) {
                    info = JSON as NSDictionary
                    callback(info)
                } else {
                    println(error)
                    info = ["success": -1, "message": "no wifi"]
                    callback(info)
                }
        }
    }
}