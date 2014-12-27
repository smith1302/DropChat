//
//  LoginViewController.swift
//  DropChat
//
//  Created by Eric Smith on 12/3/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FBLoginViewDelegate {

    
    @IBOutlet weak var fbLoginView: FBLoginView!
    var sentOnce = false
    var reachability: Reachability = Reachability()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends"]
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        sentOnce = false
    }
    
//    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
//        println("User Logged In")
//        let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("NavigationController") as UIViewController
//        self.showViewController(navigationController, sender: self)
//    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        showAlertWithMessage("Drop Chat", message: "Could not connect to Facebook.")
        println("Error: \(handleError.localizedDescription)")
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        if (!Reachability.isConnectedToNetwork()) {
            showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
            return
        }
        if (!sentOnce) {
            sentOnce = true
            var profile_image = "http://graph.facebook.com/\(user.objectID)/picture?type=large"
            var userEmail = user.objectForKey("email") as String
            var fbid = user.objectID
            var name = user.name
            NSUserDefaults.standardUserDefaults().setObject(fbid, forKey: "fbid")
            NSUserDefaults.standardUserDefaults().setObject(profile_image, forKey: "profile_image")
            NSUserDefaults.standardUserDefaults().synchronize()
            let ls = LoginService()
            ls.register(fbid, email: userEmail, name: name, profile_image: profile_image)
            let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("NavigationController") as UIViewController
            self.showViewController(navigationController, sender: self)
        }
    }
    
    func showAlertWithMessage(title:String, message:String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
