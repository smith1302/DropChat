//
//  LoginService.swift
//  DropChat
//
//  Created by Eric Smith on 12/16/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import Alamofire

class LoginService: NSObject {
    
    func register(fbid:String, email:String, name:String, profile_image:String) {
        var info:NSDictionary!
        
        Alamofire.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/register.php",
            parameters: ["fbid":fbid, "email":email, "name":name, "profile_image":profile_image]
            )
            .responseString{ (request, response, String, error) in
                println(String)
            }
    }
}