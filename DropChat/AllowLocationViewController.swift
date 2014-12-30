//
//  AllowLocationViewController.swift
//  DropChat
//
//  Created by Eric Smith on 12/28/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class AllowLocationViewController: UIViewController, CLLocationManagerDelegate {

    let locManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func allowPress(sender: UIButton) {
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if (locManager.respondsToSelector(Selector("requestWhenInUseAuthorization"))) {
            locManager.requestWhenInUseAuthorization()
        }
        locManager.startUpdatingLocation()
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Authorized) {
            self.continueToNext()
        }
        if !(CLLocationManager.locationServicesEnabled()) {
            showAlertWithMessage("Drop Chat", message: "Your device has location services disabled. You can enable them in privacy settings.")
            return
        }
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied) {
            showAlertWithMessage("Drop Chat", message: "You have chosen to disable location services. You can re-enable them in privacy settings.")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.Restricted:
            return
        case CLAuthorizationStatus.Denied:
            return
        case CLAuthorizationStatus.NotDetermined:
            return
        default:
            self.continueToNext()
        }
    }
    
    func continueToNext() {
        let next = self.storyboard?.instantiateViewControllerWithIdentifier("noteViewController") as UIViewController
        if (self.respondsToSelector(Selector("showViewController"))) {
            self.showViewController(next, sender: self)
        } else {
            self.presentViewController(next, animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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

}
