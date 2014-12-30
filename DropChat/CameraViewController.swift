//
//  CameraViewController.swift
//  DropChat
//
//  Created by Eric Smith on 12/5/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class CameraViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, CLLocationManagerDelegate, FBLoginViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholder: UILabel!
    @IBOutlet weak var charCountLabel: UILabel!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    var locManager:CLLocationManager!
    var fbid:String!
    let maxCharCount: Int = 175
    let ms = MarkerService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Creates the Drop Chat logo in the navbar
        Helper.makeImageForNavBar(self.navigationItem)
        // hide loader
        loader.stopAnimating()
        loader.hidden = true
        //get fbid
        self.fbid = NSUserDefaults.standardUserDefaults().objectForKey("fbid") as String
        // Facebook stuff
        var fbLoginView = FBLoginView()
        fbLoginView.delegate = self
        fbLoginView.readPermissions = ["public_profile", "email", "user_friends"]
        
        // Setup our Location Manager
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if (locManager.respondsToSelector(Selector("requestWhenInUseAuthorization"))) {
            locManager.requestWhenInUseAuthorization()
        }
        
        textView.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        charCountLabel.text = String(maxCharCount)
        self.textView.becomeFirstResponder()
//        
//        let mainImage = UIImageView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width))
//        mainImage.image = UIImage(named: "test-feature.jpg")
//        self.view.addSubview(mainImage)
//        let displacement = self.view.frame.size.width + 20
//        var tvf = textView.frame
//        var phf = placeholder.frame
//        var cclf = charCountLabel.frame
//        tvf.origin.y += displacement
//        phf.origin.y += displacement
//        cclf.origin.y += displacement
//        textView.frame = tvf
//        placeholder.frame = phf
//        charCountLabel.frame = cclf
        //self.takePhoto()
    }
    
    @IBAction func doneClick(sender: UIBarButtonItem) {
        if (countElements(textView.text) < 3) {
            showAlertWithMessage("Drop Chat", message: "Must be atleast 3 characters!")
            return
        }
        self.takePhoto()
        placeholder.hidden = true
        loader.startAnimating()
        loader.hidden = false
        //ms.addMarker(text, fbid: self.fbid, latitude: lat, longitude: long, image_url: "", addMarkerCallback)
    }
    
    func addMarkerCallback(data:NSDictionary) {
        var success = data["success"] as Int
        if (success == 1) {
            let viewControllers:[AnyObject] = (self.navigationController?.viewControllers)!
            let rootViewController:MapViewController = viewControllers[viewControllers.count - 2] as MapViewController
            rootViewController.hasLoadedMarkers = false
            rootViewController.refresh()
            self.navigationController?.popToRootViewControllerAnimated(true)
        } else if (success == -1) {
            enableBarButtons(true)
            showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
        } else {
            enableBarButtons(true)
            showAlertWithMessage("Drop Chat", message: "Something went wrong!")
        }
        loader.stopAnimating()
        loader.hidden = true
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        let newLength = countElements(textView.text!) + countElements(text)
        return newLength <= maxCharCount //Bool
    
    }
    
    /* Check if text view is empty or not, to show placeholder */
    func textViewDidEndEditing(textView: UITextView) {
        UIView.animateWithDuration(0.15, animations: {
            self.placeholder.alpha = 1
        });
    }
    
    func textViewDidChange(textView: UITextView) {
        if (!textView.hasText()) {
            UIView.animateWithDuration(0.15, animations: {
                self.placeholder.alpha = 1
            });
        } else {
            UIView.animateWithDuration(0.15, animations: {
                self.placeholder.alpha = 0
            });
        }
        charCountLabel.text = String(maxCharCount - countElements(textView.text!))
    }
    
    func takePhoto() {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            var picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            var mediaTypes: Array<AnyObject> = [kUTTypeImage]
            picker.mediaTypes = mediaTypes
            picker.allowsEditing = true
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else{
            println("No Camera.")
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: NSDictionary!) {
        NSLog("Did Finish Picking")
        let mediaType = info[UIImagePickerControllerMediaType] as String
        var originalImage:UIImage?, editedImage:UIImage?, imageToSave:UIImage?, imageData:NSData?
        
        // Handle a still image capture
        let compResult:CFComparisonResult = CFStringCompare(mediaType as NSString!, kUTTypeImage, CFStringCompareFlags.CompareCaseInsensitive)
        if ( compResult == CFComparisonResult.CompareEqualTo ) {
            
            editedImage = info[UIImagePickerControllerEditedImage] as UIImage?
            originalImage = info[UIImagePickerControllerOriginalImage] as UIImage?
            if ( editedImage == nil ) {
                imageData = UIImageJPEGRepresentation(editedImage, 0.5)
            } else {
                imageData = UIImageJPEGRepresentation(editedImage, 0.5)
            }
            if (!Reachability.isConnectedToNetwork()) {
                picker.dismissViewControllerAnimated(true, completion: nil)
                addMarkerCallback(["success": -1, "message":"no wifi"])
                return
            }
            var text = textView.text
            var lat = locManager.location.coordinate.latitude
            var long = locManager.location.coordinate.longitude
            ms.addMarker(text, fbid: self.fbid, latitude: lat, longitude: long, image_data: imageData!, addMarkerCallback: addMarkerCallback)
            enableBarButtons(false)
        }
        
        picker.dismissViewControllerAnimated(true, completion: nil)

    }
    
    func enableBarButtons(val: Bool) {
        self.navigationItem.leftBarButtonItem?.enabled = val
        self.navigationItem.rightBarButtonItem?.enabled = val
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        loader.stopAnimating()
        loader.hidden = true
        picker.dismissViewControllerAnimated(true, completion: nil)
        textView.becomeFirstResponder()
    }

}
