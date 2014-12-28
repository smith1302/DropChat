//
//  MarkerService.swift
//  DropChat
//
//  Created by Eric Smith on 12/13/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import Alamofire

class MarkerService: NSObject {
    
    func getMarkersLimit(fbid:String, latitude:Double, longitude:Double, distance: Double, markerReceived: (NSDictionary) -> (), limit: Int, orderBy: String) {
        var info:NSDictionary!
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            markerReceived(info)
            return
        }
        Alamofire.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/getMarkers.php",
            parameters: ["fbid":fbid, "latitude":latitude, "longitude":longitude, "distance":distance, "limit": limit, "order": orderBy]
            )
            .responseJSON{ (request, response, JSON, error) in
                if (JSON != nil) {
                    info = JSON as NSDictionary
                    markerReceived(info)
                } else {
                    info = ["success": -1, "message":"no wifi"]
                    markerReceived(info)
                }
        }
    }

    func getMarkers(fbid:String, latitude:Double, longitude:Double, distance: Double, markerReceived: (NSDictionary) -> ()) {
        getMarkersLimit(fbid, latitude: latitude, longitude: longitude, distance: distance, markerReceived: markerReceived, limit: 60, orderBy: "")
    }
    
    func addMarker(text:String, fbid:String, latitude:Double, longitude:Double, image_data:NSData, addMarkerCallback: (NSDictionary) -> ()) {
        var info:NSDictionary!
        // Return false if no active wifi connection
        if (!Reachability.isConnectedToNetwork()) {
            info = ["success": -1, "message":"no wifi"]
            addMarkerCallback(info)
            return
        }
        var latString:String = String(format:"%f", latitude)
        var longString:String = String(format:"%f", longitude)
        var parameters = ["fbid":fbid, "latitude":latString, "longitude":longString, "text":text]
        let urlRequest = urlRequestWithComponents("http://www.hiddenninjagames.com/DropChat/DB/addMarker.php", parameters: parameters, imageData: image_data)
        
        Alamofire.upload(urlRequest.0, urlRequest.1)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                println("\(totalBytesWritten) / \(totalBytesExpectedToWrite)")
            }
            .responseJSON{ (request, response, JSON, error) in
                info = JSON as NSDictionary
                addMarkerCallback(info)
            }
        
//        Alamofire.request(
//                .POST,
//                "http://www.hiddenninjagames.com/DropChat/DB/addMarker.php",
//                parameters: ["fbid":fbid, "latitude":latitude, "longitude":longitude, "text":text, "image_url":file]
//            )
//            .responseJSON{ (request, response, JSON, error) in
//                info = JSON as NSDictionary
//                addMarkerCallback(info)
//            }
    }
    
    func hideMarker(fbid:String, markerID:Int) {
        var info:NSDictionary!
        
        Alamofire.request(
            .POST,
            "http://www.hiddenninjagames.com/DropChat/DB/hideMarker.php",
            parameters: ["markerID":markerID, "fbid":fbid]
            )
            .responseJSON{ (request, response, JSON, error) in
                println(JSON)
        }
    }
    
    
    // this function creates the required URLRequestConvertible and NSData we need to use Alamofire.upload
    func urlRequestWithComponents(urlString:String, parameters:Dictionary<String, String>, imageData:NSData) -> (URLRequestConvertible, NSData) {
        
        // create url request to send
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Alamofire.Method.POST.rawValue
        let boundaryConstant = "myRandomBoundary12345";
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        
        
        // create upload data to send
        let uploadData = NSMutableData()
        
        // add image
        uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"file.png\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Type: image/png\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData(imageData)
        
        // add parameters
        for (key, value) in parameters {
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        // return URLRequestConvertible and NSData
        return (Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }
}
