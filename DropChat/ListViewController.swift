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
    var loadingIndicator: LoadingIndicator!

    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var bgView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Creates the Drop Chat logo in the navbar
        Helper.makeImageForNavBar(self.navigationItem, leftOffset: -55)
        self.fbid = NSUserDefaults.standardUserDefaults().objectForKey("fbid") as String
        self.hasLocation = false
        self.tableView.separatorStyle = .None
        //UIColor(red: 193/255.0, green: 215/255.0, blue: 235/255.0, alpha: 1)
        self.view.backgroundColor = UIColor(red: 210/255.0, green: 229/255.0, blue: 241/255.0, alpha: 1)
        self.refreshController.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshController)
        self.tableView.sendSubviewToBack(refreshController)
        // Setup our Location Manager
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if (locManager.respondsToSelector(Selector("requestWhenInUseAuthorization"))) {
            locManager.requestWhenInUseAuthorization()
        }
        locManager.startUpdatingLocation()
        
        if (CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Authorized || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse)) {
            loadingIndicator = LoadingIndicator(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.height))
            self.view.addSubview(loadingIndicator)
            loadingIndicator.startLoading()
        } else {
            showAlertWithMessage("Drop Chat", message: "To see posts near you, enable location services in your device's privacy settings.")
        }
        
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            tableView.estimatedRowHeight = 410
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if (markerArray.count == 0 && hasLocation == true) {
            self.refresh()
        }
    }
    
    // Location handling
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as CLLocation
        userLocation = location
        if (!hasLocation) {
            ms.getMarkersLimit(self.fbid, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, distance:20, markerReceived: self.markersReceived, limit: 25, orderBy: "numComments DESC")
            hasLocation = true
        }
    }
    
    func refresh()
    {
        if (!CLLocationManager.locationServicesEnabled() || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied) {
            showAlertWithMessage("Drop Chat", message: "To see posts near you, enable location services in your device's privacy settings.")
            return
        }
        ms.getMarkersLimit(self.fbid, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, distance:20, markerReceived: self.markersReceived, limit: 25, orderBy: "numComments DESC")
    }
    
    // Location Manager Delegate stuff
    // If failed
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locManager.stopUpdatingLocation()
        println(error)
    }
    
    func markersReceived(data:NSDictionary) {
        if var success = data["success"] as? Int {
            if (success != 1) {
                self.showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
                self.refreshController.endRefreshing()
                loadingIndicator.stopLoading()
                return
            }
            var tempRowToMarkerID = [Int]()
            var tempMarkerArray = [Int : [String: AnyObject]]()
            // Iterate and store markers
            var markers: Array? = (data["message"] as Array<NSDictionary>)
            for marker:NSDictionary in (markers as Array!) {
                var hasViewed = marker.objectForKey("hasViewed") as String
                var hasViewedBool = (hasViewed == "1" ? true : false)
                var markerID = (marker.objectForKey("markerID") as String).toInt()
                // If it doesnt exist in our array lets add it

                tempMarkerArray[markerID!] = [
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
            }
            
            rowToMarkerID = tempRowToMarkerID
            markerArray = tempMarkerArray
        }
        self.refreshController.endRefreshing()
        loadingIndicator.stopLoading()
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
        return max(1,markerArray.count)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (markerArray.count == 0) {
            var cell = tableView.dequeueReusableCellWithIdentifier("defaultCell") as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
            }
            cell?.textLabel?.textColor = UIColor.lightGrayColor()
            cell?.textLabel?.text = "No new drops in your area."
            cell?.textLabel?.textAlignment = .Center
            return cell!
        } else {
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
    
        var viewPostController = ViewPostCache.sharedManager.viewPosts[markerID]
        if viewPostController == nil {
            viewPostController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewPostController") as? ViewPostController
            ViewPostCache.sharedManager.viewPosts[markerID] = viewPostController
        }
        var coordinate = CLLocationCoordinate2DMake(markerArray[markerID]?["latitude"] as Double, markerArray[markerID]?["longitude"] as Double)
        viewPostController?.coordinate = coordinate
        viewPostController?.marker_image = markerArray[markerID]?["marker_image"] as String
        viewPostController?.text = markerArray[markerID]?["text"] as String
        viewPostController?.markerID = markerArray[markerID]?["markerID"] as Int
        viewPostController?.authorID = markerArray[markerID]?["authorID"] as String
        viewPostController?.author_name = markerArray[markerID]?["author_name"] as String
        viewPostController?.created = markerArray[markerID]?["created"] as String
        viewPostController?.hasViewed = markerArray[markerID]?["hasViewed"] as Bool
        viewPostController?.numComments = markerArray[markerID]?["numComments"] as Int
        if (self.respondsToSelector(Selector("showViewController"))) {
            self.showViewController(viewPostController!, sender: self)
        } else {
            self.navigationController?.pushViewController(viewPostController!, animated: true)
        }
        
        if (!(markerArray[markerID]?["hasViewed"] as Bool)) {
            vps.setMarkerSeen(fbid, markerID: (markerArray[markerID]?["markerID"] as Int))
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (self.markerArray.count == 0) {
            return 60
        }
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            return UITableViewAutomaticDimension
        }
        return 410
    }

//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        var cell = tableView.dequeueReusableCellWithIdentifier("listViewCell", forIndexPath: indexPath) as ListViewCell
//        return cell.bgView.frame.size.height + 20
//    }
    
    // HELPERS
    
    func isMarkerExpired(createdDate:NSDate) -> Bool {
        let expirationDate = createdDate.dateByAddingTimeInterval(60*60*24)
        var timeSinceExpirationDate = expirationDate.timeIntervalSinceNow
        // If timeSinceExpirationDate is negative this means current date has already passed
        return timeSinceExpirationDate < 0
    }
    
    func showAlertWithMessage(title:String, message:String) {
        if objc_getClass("UIAlertController") != nil {
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            var alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "Okay")
            alert.show()
        }
    }
    
    func stringToDate(time:String) -> NSDate {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "PST")
        var createdDate = dateFormatter.dateFromString(time)
        return createdDate!
    }

}
