//
//  MapViewController.swift
//  DropChat
//
//  Created by Eric Smith on 12/3/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

//So how it works. We start up our location manager. When a location is updated the locationUpdated function fires.
//We have a boolean variable and if this is the first update we use that location to get markers. When the markers are loaded
//then we start a timer to wait for the mapview to show the annotation

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, FBLoginViewDelegate, UIActionSheetDelegate, UITabBarDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    // Holds the markers on the map (visible cause some are in the reuse queue)
    var markerDictionary = [Int: CustomAnnotationView]()
    var markersThatExist = [Int : Bool]()
    var locManager:CLLocationManager!
    var listViewController: ListViewController!
    var fbid:String!
    // First few map calls are inaccurate so wait
    var hasLoadedMarkers:Bool = false;
    var ms:MarkerService = MarkerService()
    let vps:ViewPostService = ViewPostService()
    var loadingIndicator:LoadingIndicator!
    var waitForLocationTimer:NSTimer!
    var imageCache = [String : UIImage]()
    
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        self.navigationItem.backBarButtonItem = backButton
        self.tabBar.delegate = self
        
        self.fbid = NSUserDefaults.standardUserDefaults().objectForKey("fbid") as String
        // Setup our Location Manager
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if(locManager!.respondsToSelector("requestWhenInUseAuthorization")) {
            locManager!.requestWhenInUseAuthorization()
        }
        locManager.startUpdatingLocation()
        var center = CLLocationCoordinate2D(
            latitude: 29.652,
            longitude: -82.325
        )
        var span = MKCoordinateSpan(
            latitudeDelta: 0.02,
            longitudeDelta: 0.02
        )
        var region = MKCoordinateRegion( center: center, span: span )
        self.mapView.setRegion(region, animated: true)
        if (!CLLocationManager.locationServicesEnabled()) {
            showAlertWithMessage("Drop Chat", message: "To see posts near you, enable location services!")
        }
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.userLocation.title = ""
        hasLoadedMarkers = false;
        // Draw loading indicator
        loadingIndicator = LoadingIndicator(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.height))
        self.view.addSubview(loadingIndicator)
        loadingIndicator.startLoading()
    }
    
    func refresh() {
        // Reset this so markers get pulled again
        // Only if its over cacheLoadMin, meaning its been loaded before
//        if ( cacheLoadCount  > cacheLoadMin) {
//            cacheLoadCount = cacheLoadMin
//        }
        // Loading stuff
        loadingIndicator.startLoading()
        println("Refreshing method, getting markers")

        ms.getMarkers(self.fbid, latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude, distance:getSpanDistance(), self.markersReceived)
    }
    
    @IBAction func refresh(sender: UIButton) {
        let duration = 1.0
        let delay = 0.0
        let options = UIViewKeyframeAnimationOptions.CalculationModeLinear
        var view: UIView = self.refreshButton.valueForKey("view") as UIView
        var fullRotation = CGFloat(M_PI*2)
        UIView.animateKeyframesWithDuration(duration, delay: delay, options: options,
            animations: {
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1/3, animations: {
                    view.transform = CGAffineTransformMakeRotation(1/3 * fullRotation)
                })
                UIView.addKeyframeWithRelativeStartTime(1/3, relativeDuration: 1/3, animations: {
                    view.transform = CGAffineTransformMakeRotation(2/3 * fullRotation)
                })
                UIView.addKeyframeWithRelativeStartTime(2/3, relativeDuration: 1/3, animations: {
                    view.transform = CGAffineTransformMakeRotation(3/3 * fullRotation)
                })
            }, completion: nil)

        refresh()
    }
    
    // Returns miles
    func getSpanDistance() -> Double {
        let spanLat = self.mapView.region.span.latitudeDelta
        let spanLong = self.mapView.region.span.longitudeDelta
        let maxDelta = max(spanLat, spanLong)
        // miles = delta*69 with a buffer of 1.5
        let distance = (maxDelta * 69)*2
        return (distance < 15) ? 15 : distance
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        var name:String = item.title!
        if (name == "Locate") {
            if let loc = self.mapView?.userLocation?.location {
                updateUserLoc(loc)
            }
        } else if (name == "New") {
            let cvc = self.storyboard?.instantiateViewControllerWithIdentifier("CameraViewController") as CameraViewController
            self.showViewController(cvc, sender: self)
        } else if (name == "List") {
            if (listViewController == nil) {
                listViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ListViewController") as ListViewController
            }
            self.showViewController(listViewController, sender: self)
        }
    }
    
    /* Check if logged out of Facebook */
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!) {
        println("User Logged Out")
        let loginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as UIViewController
        self.showViewController(loginViewController, sender: self)
    }
    
    func addMarker(coord: CLLocationCoordinate2D, data: NSDictionary) {
        var information = CustomMKAnnotation(
                                                coordinate: coord,
                                                markerData: data
                                            )
        
        var created = data.objectForKey("created") as String
        let createdDate = stringToDate(created)
        let expired = isMarkerExpired(createdDate)
        println("Preparing --")
        println((data.objectForKey("text") as String))
        // Only add it if its not in the Dictionary, otherwise just update the num comments or delete it
        var markerID:Int = (data.objectForKey("markerID") as String).toInt()!
        if let marker = markerDictionary[markerID] {
                println("editing it")
                var numComments = (data.objectForKey("numComments") as String).toInt()
                if (!expired) {
                    marker.setNumComments(numComments!)
                } else {
                    self.mapView.removeAnnotation(marker.annotation)
                    markerDictionary[markerID] = nil
                    markersThatExist[markerID] = nil
                }
        } else { // doesnt exist, add it
            if (!expired) {
                println("will add it")
                self.mapView.addAnnotation(information)
                let customMarker:CustomAnnotationView = CustomAnnotationView(annotation: information, reuseIdentifier: (data.objectForKey("markerID") as String), selfView: self) as CustomAnnotationView
                customMarker.setMarkerData(
                    coord,
                    markerData: data
                )
                markerDictionary[markerID] = customMarker
            }
        }
    }
    
    func updateUserLoc(location: CLLocation) {
        let spanX = 0.01
        let spanY = 0.01
        var newRegion = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        self.mapView.setRegion(newRegion, animated: true)
    }
    
    /* Handle what happens when we change location */
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        let location = locations.last as CLLocation
        if (location.coordinate.latitude != 0 && location.coordinate.latitude != 0) {
            if (!hasLoadedMarkers) {
                self.updateUserLoc(location)
                ms.getMarkers(self.fbid, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, distance:getSpanDistance(), self.markersReceived)
                hasLoadedMarkers = true
            }
        }
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
            if (success == -1) {
                showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
            } else {
                println("markers not received")
                println("Error: \(data)")
            }
            loadingIndicator.stopLoading()
            if (waitForLocationTimer != nil) {
                waitForLocationTimer.invalidate()
                waitForLocationTimer = nil
            }
            return
        }
        var diff = [Int: Bool]()
        // To remove markers that dont exist anymore
        for (myKey,myValue) in markerDictionary {
            // put all IDs of our local markers into array
            diff[myKey] = true
        }
        var markers: Array? = (data["message"] as Array<NSDictionary>)
        for marker:NSDictionary in (markers as Array!) {
            var latitude = (marker.objectForKey("latitude") as NSString).doubleValue
            var longitude = (marker.objectForKey("longitude") as NSString).doubleValue
            var markerID = (marker.objectForKey("markerID") as String).toInt()
            addMarker(CLLocationCoordinate2DMake(latitude, longitude), data: marker)
            if let doesExist = diff[markerID!] {
                // Set any overlapping markerIDs to false
                diff[markerID!] = false
            }
        }
        // Any markerIDs still true dont exist anymore. Remove them
        for (myKey,myValue) in diff {
            if (myValue == true) {
                self.mapView.removeAnnotation(markerDictionary[myKey]?.annotation)
                markerDictionary[myKey] = nil
                markersThatExist[myKey] = nil
            }
        }
        // Now that markers are received, start a timer that waits for user location to be available
        waitForLocationTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("waitForAvailableLocation"), userInfo: nil, repeats: true)
    }
    
    // If loc available and markers are retreived then stop loading
    func waitForAvailableLocation() {
        if (self.mapView?.userLocation?.location != nil) {
            loadingIndicator.stopLoading()
            if (waitForLocationTimer != nil) {
                waitForLocationTimer.invalidate()
                waitForLocationTimer = nil
            }
        }
    }
    
    func showAlertWithMessage(title:String, message:String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if !(annotation is CustomMKAnnotation) {
            return nil
        }
        var customAnnotation = annotation as CustomMKAnnotation
        let reuseId = customAnnotation.markerData.objectForKey("markerID") as String
        var markerID:Int = reuseId.toInt()!
        var markerView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if markerView == nil {
            markerView = markerDictionary[markerID]
            let customMarker = markerView as CustomAnnotationView
            println("Adding Marker:")
            println(customMarker.text)
            customMarker.setNeedsDisplay()
            customMarker.frame = CGRectMake(0, 0, 44, 56)
            customMarker.backgroundColor = UIColor.clearColor()
            customMarker.centerOffset = CGPointMake(0, -28)
            customMarker.canShowCallout = false
            customMarker.enabled = true
        }
        else {
            markerView!.annotation = annotation
        }
        
        return markerView
    }
    
//    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
//        if !(view is CustomAnnotationView) {
//            return
//        }
//    }
    
    func openViewPost(customAnnotation: CustomAnnotationView) {
        if (isMarkerExpired(stringToDate(customAnnotation.created))) {
            showAlertWithMessage("Drop Chat", message: "This post has just expired!")
            self.refresh()
            return
        }
        
        let viewPostController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewPostController") as ViewPostController
        viewPostController.coordinate = customAnnotation.coordinate
        viewPostController.marker_image = customAnnotation.marker_image
        viewPostController.text = customAnnotation.text
        viewPostController.markerID = customAnnotation.markerID
        viewPostController.authorID = customAnnotation.authorID
        viewPostController.author_name = customAnnotation.author_name
        viewPostController.created = customAnnotation.created
        viewPostController.hasViewed = customAnnotation.hasViewed
        viewPostController.numComments = customAnnotation.numComments
        self.showViewController(viewPostController, sender: self)
        
        if (!customAnnotation.hasViewed) {
            vps.setMarkerSeen(fbid, markerID: customAnnotation.markerID)
            customAnnotation.setHasViewed(true)
        }
        
        if let selectedAnnotations = mapView?.selectedAnnotations as? [CustomMKAnnotation] {
            for annotation in selectedAnnotations {
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
    }
    
    /* Get error from Facebook info access */

    func loginView(loginView : FBLoginView!, handleError:NSError) {
        println("Error: \(handleError.localizedDescription)")
    }
    
    /* Facebook part */
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        self.fbid = user.objectID
    }
    
    /* Date manipulation/checking */
    
    func stringToDate(time:String) -> NSDate {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "PST")
        var createdDate = dateFormatter.dateFromString(time)
        return createdDate!
    }
    
    func isMarkerExpired(createdDate:NSDate) -> Bool {
        let expirationDate = createdDate.dateByAddingTimeInterval(60*60*24)
        var timeSinceExpirationDate = expirationDate.timeIntervalSinceNow
        // If timeSinceExpirationDate is negative this means current date has already passed
        return timeSinceExpirationDate < 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
