//
//  ViewPostService.swift
//  DropChat
//
//  Created by Eric Smith on 12/15/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

class ViewPostService: NSObject {
    
    func addComment(fbid:String, text:String, markerID:Int, commentAdded: (NSDictionary) -> ()) {
        var info:NSDictionary!
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            commentAdded(info)
            return
        }
        
        Alamofire.manager.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/addComment.php",
            parameters: ["fbid":fbid, "text":text, "markerID":markerID, "token":TokenCache.sharedManager.tokenCache]
            )
            .responseJSON{ (request, response, JSON, error) in
                if (JSON != nil) {
                    info = JSON as NSDictionary
                    commentAdded(info)
                } else {
                    info = ["success": -1, "message":"no wifi"]
                    commentAdded(info)
                }
            }
    }
    
    func getComments(fbid:String, markerID:Int, commentsReceived: (NSDictionary) -> ()) {
        var info:NSDictionary!
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            commentsReceived(info)
            return
        }
        Alamofire.manager.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/getComments.php",
            parameters: ["fbid":fbid, "markerID":markerID, "token":TokenCache.sharedManager.tokenCache]
        )
        .responseJSON{ (request, response, JSON, error) in
            if (JSON != nil) {
                info = JSON as NSDictionary
                commentsReceived(info)
            } else {
                println(error)
                info = ["success": -1, "message":"no wifi"]
                commentsReceived(info)
            }
        }
    }
    
    func vote(vote:Int, fbid:String, commentID:Int, markerID:Int, voteReceived: (NSDictionary) -> ()) {
        var info:NSDictionary!
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            voteReceived(info)
            return
        }
        Alamofire.manager.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/vote.php",
            parameters: ["vote":vote, "markerID":markerID, "fbid":fbid, "commentID":commentID, "token":TokenCache.sharedManager.tokenCache]
            )
            .responseJSON{ (request, response, JSON, error) in
                info = JSON as NSDictionary
                voteReceived(info)
        }
    }
    
    func setMarkerSeen(fbid:String, markerID:Int) {
        var info:NSDictionary!

        Alamofire.manager.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/viewMarker.php",
            parameters: ["markerID":markerID, "fbid":fbid, "token":TokenCache.sharedManager.tokenCache]
            )
            .responseJSON{ (request, response, JSON, error) in
                println(JSON)
        }
    }
   
}
