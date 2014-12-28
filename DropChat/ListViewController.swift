//
//  ListViewController.swift
//  DropChat
//
//  Created by Eric Smith on 12/26/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController, CLLocationManagerDelegate{
    
    var markerArray = [Int : [String: AnyObject]]()
    var markerIDs = [Int: Bool]()
    var rowToMarkerID = [Int]()
    var hasLocation: Bool!
    var fbid:String!
    var locManager:CLLocationManager!
    var ms:MarkerService = MarkerService()
    let vps:ViewPostService = ViewPostService()
    var userLocation: CLLocation!
    let refreshController = UIRefreshControl()

    @IBOutlet weak var filterControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fbid = NSUserDefaults.standardUserDefaults().objectForKey("fbid") as String
        self.hasLocation = false
        self.tableView.separatorStyle = .None
        //self.view.backgroundColor = UIColor(red: 130/255.0, green: 161/255.0, blue: 201/255.0, alpha: 1)
        self.refreshController.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshController)
        self.tableView.sendSubviewToBack(refreshController)
        self.refreshController.beginRefreshing()
        // Setup our Location Manager
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if(locManager!.respondsToSelector("requestWhenInUseAuthorization")) {
            locManager!.requestWhenInUseAuthorization()
        }
        locManager.startUpdatingLocation()
    }
    
    // Location handling
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (!hasLocation) {
            let location = locations.last as CLLocation
            userLocation = location
            ms.getMarkersLimit(self.fbid, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, distance:20, markerReceived: self.markersReceived, limit: 25, orderBy: "numComments DESC")
            hasLocation = true
        }

    }
    
    func refresh()
    {
        ms.getMarkersLimit(self.fbid, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, distance:20, markerReceived: self.markersReceived, limit: 25, orderBy: "numComments DESC")
    }
    
    // Location Manager Delegate stuff
    // If failed
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locManager.stopUpdatingLocation()
        println(error)
    }
    
    func markersReceived(data:NSDictionary) {
        var success = data["success"] as Int
        if (data.count == 0) || (success != 1) {
            self.showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
            return
        }
        var tempRowToMarkerID = [Int]()
        // Iterate and store markers
        var markers: Array? = (data["message"] as Array<NSDictionary>)
        println(markers)
        for marker:NSDictionary in (markers as Array!) {
            var hasViewed = marker.objectForKey("hasViewed") as String
            var hasViewedBool = (hasViewed == "1" ? true : false)
            var markerID = (marker.objectForKey("markerID") as String).toInt()
            // If it doesnt exist in our array lets add it

            markerArray[markerID!] = [
                    "latitude" : (marker.objectForKey("latitude") as NSString).doubleValue,
                    "longitude" : (marker.objectForKey("longitude") as NSString).doubleValue,
                    "text" : marker.objectForKey("text") as String,
                    "authorID" : marker.objectForKey("authorID") as String,//
                    "author_name" : marker.objectForKey("author_name") as String,//
                    "markerID" : ((marker.objectForKey("markerID") as String).toInt())!,//
                    "marker_image" : marker.objectForKey("image_url") as String,
                    "numComments" : ((marker.objectForKey("numComments") as String).toInt())!,
                    "created" : marker.objectForKey("created") as String,
                    "hasViewed": hasViewedBool
            ]
            // Why I made 2 arrays for this? Cause I'm dumb. Change later
            tempRowToMarkerID.append(markerID!)
            rowToMarkerID = tempRowToMarkerID
        }
        
        self.refreshController.endRefreshing()
        // Now that we have an array of data, lets reload the table to render it
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return markerArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("listViewCell", forIndexPath: indexPath) as ListViewCell
        var markerID = rowToMarkerID[indexPath.row]
        var numComments: Int = markerArray[markerID]?["numComments"] as Int
        var text: String = markerArray[markerID]?["text"] as String
        var image_url: String = markerArray[markerID]?["marker_image"] as String
        var author: String = markerArray[markerID]?["author_name"] as String
        var lat: Double = markerArray[markerID]?["latitude"] as Double
        var long: Double = markerArray[markerID]?["longitude"] as Double
        var distance: Double = 0.8
        var meters = userLocation.distanceFromLocation(CLLocation(latitude: lat, longitude: long))
        var miles = meters * 0.000621371
        cell.setData(numComments, text: text, image_url: image_url, distance: miles, author: author, tableController: self, rowIndex: indexPath.row)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.openViewPost(indexPath.row)
    }

    func openViewPost(rowIndex: Int) {
        var markerID = rowToMarkerID[rowIndex]
        if (isMarkerExpired(stringToDate(markerArray[markerID]?["created"] as String))) {
            showAlertWithMessage("Drop Chat", message: "This post has just expired!")
            // Should REFRESH HERE!!
            self.refreshController.beginRefreshing()
            return
        }
        
        let viewPostController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewPostController") as ViewPostController
        var coordinate = CLLocationCoordinate2DMake(markerArray[markerID]?["latitude"] as Double, markerArray[markerID]?["longitude"] as Double)
        viewPostController.coordinate = coordinate
        viewPostController.marker_image = markerArray[markerID]?["marker_image"] as String
        viewPostController.text = markerArray[markerID]?["text"] as String
        viewPostController.markerID = markerArray[markerID]?["markerID"] as Int
        viewPostController.authorID = markerArray[markerID]?["authorID"] as String
        viewPostController.author_name = markerArray[markerID]?["author_name"] as String
        viewPostController.created = markerArray[markerID]?["created"] as String
        viewPostController.hasViewed = markerArray[markerID]?["hasViewed"] as Bool
        viewPostController.numComments = markerArray[markerID]?["numComments"] as Int
        self.showViewController(viewPostController, sender: self)
        
        if (!(markerArray[markerID]?["hasViewed"] as Bool)) {
            vps.setMarkerSeen(fbid, markerID: (markerArray[markerID]?["markerID"] as Int))
        }
    }

    /*func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 452.0
        } else {
            return 119.0
        }
    }*/
        
    // HELPERS
    
    func isMarkerExpired(createdDate:NSDate) -> Bool {
        let expirationDate = createdDate.dateByAddingTimeInterval(60*60*24)
        var timeSinceExpirationDate = expirationDate.timeIntervalSinceNow
        // If timeSinceExpirationDate is negative this means current date has already passed
        return timeSinceExpirationDate < 0
    }
    
    func showAlertWithMessage(title:String, message:String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func stringToDate(time:String) -> NSDate {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "PST")
        var createdDate = dateFormatter.dateFromString(time)
        return createdDate!
    }

}
