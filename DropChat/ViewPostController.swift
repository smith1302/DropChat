//
//  ViewPostController.swift
//  DropChat
//
//  Created by Eric Smith on 12/5/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class ViewPostController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    var commentsArray: [[String:Any]] = []
    var tempCommentsArray: [[String:Any]] = []
    var numCommentsToLoad: Int = -1
    var fbid: String!
    var vps: ViewPostService!
    var coordinate: CLLocationCoordinate2D!
    var marker_image: String!
    var text: String!
    var markerID: Int!
    var authorID: String!
    var author_name: String!
    var created: String!
    var timeLeft: String!
    var hasViewed: Bool = false
    var numComments: Int = 0
    var firstLoad:Bool = true
    
    // textview stuff
    var pcvFrame: CGRect!
    var ctFrame: CGRect!
    let refreshControl = UIRefreshControl()

    @IBOutlet weak var postCommentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentText: UITextView!
    @IBOutlet weak var postBtn: UIButton!
    @IBOutlet weak var placeholder: UILabel!
    
    @IBOutlet weak var voteView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem?.title = "Back"
        self.view.bringSubviewToFront(self.postCommentView)
//        // Pull to refresh
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.tableView.sendSubviewToBack(refreshControl)
        self.tableView.backgroundColor = UIColorFromRGB(0xE8E8E8)//UIColorFromRGB(0xFAEDD9)
        self.tableView.layoutMargins = UIEdgeInsetsZero;
        self.tableView.separatorInset = UIEdgeInsetsZero;

        // Set up the commenting text box
        self.postCommentView.layer.borderColor = UIColorFromRGB(0xDADADA).CGColor
        self.postCommentView.layer.borderWidth = 1
        self.commentText.layer.backgroundColor = UIColor.whiteColor().CGColor
        self.commentText.layer.borderColor = UIColorFromRGB(0xDDDDDD).CGColor
        self.commentText.layer.cornerRadius = 6.0
        self.commentText.layer.borderWidth = 1.0
        self.pcvFrame = postCommentView.frame
        self.ctFrame = commentText.frame
        self.commentText.delegate = self
        self.commentText.scrollEnabled = false
        self.postBtn.layer.cornerRadius = 3.0
        // Set the time left for this post
        var createdDate = self.stringToDate(self.created)
        self.timeLeft = "\(self.timeDifference(NSDate(), date2: (createdDate.dateByAddingTimeInterval(60*60*24)))) left"
        self.navigationItem.title = author_name
        // set fbid
        self.fbid = NSUserDefaults.standardUserDefaults().objectForKey("fbid") as String
        self.vps = ViewPostService()
        //Keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasHidden:", name: UIKeyboardWillHideNotification, object: nil)
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.Interactive
        // Get Comments
        vps.getComments(fbid, markerID: markerID, commentsReceived: commentsReceived)
    }
    
    func refresh(sender:AnyObject)
    {
        vps.getComments(fbid, markerID: markerID, commentsReceived: commentsReceived)
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    @IBAction func postBtn(sender: UIButton) {
        if (!Reachability.isConnectedToNetwork()) {
            showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
            return
        }
        var length = countElements(commentText.text)
        var maxChar = 110
        var minChar = 1
        if (length < minChar) {
            return
        } else if (length > 110) {
            self.showAlertWithMessage("Drop Chat", message: "Comment is too long.")
            return
        } else {
            vps.addComment(self.fbid, text: commentText.text, markerID: self.markerID, commentAdded)
        }
        self.commentText.resignFirstResponder()
        self.commentText.text = ""
        self.postCommentView.frame = pcvFrame
        self.commentText.frame = ctFrame
    }
    
    // Called when user adds a new comment
    func commentAdded(data:NSDictionary) {
        var comment = (data["message"] as NSDictionary)
        var success = data["success"] as Int
        if (success == 1) {
            var text = (comment.objectForKey("text") as String)
            var upvotes = 0
            var downvotes = 0
            var created = (comment.objectForKey("created") as String)
            var commentID = comment.objectForKey("commentID") as Int
            var registeredVoted = 0
            var commentArray: Dictionary<String, Any> = [
                "text" : text,
                "upvotes" : upvotes,
                "downvotes" : downvotes,
                "created" : created,
                "commentID": commentID,
                "registeredVote": registeredVoted
            ]
            commentsArray.append(commentArray)
            self.numComments++
            self.tableView.reloadData()
            var iPath = NSIndexPath(forRow: commentsArray.count, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(iPath, atScrollPosition: .Bottom, animated: true)
        } else if (success == -1) {
            showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
        } else {
            showAlertWithMessage("Drop Chat", message: "Something went wrong!")
        }
    }
    
    func showAlertWithMessage(title:String, message:String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Pulled from Database
    func commentsReceived(data:NSDictionary) {
        var success = data["success"] as Int
        if (success != 1) {
            showAlertWithMessage("Could not connect", message: "Please check your connection and try again.")
            return
        }
        var comments: Array? = (data["message"] as Array<NSDictionary>)
        var commentsArray: [Dictionary<String, Any>] = []
        for comment:NSDictionary in (comments as Array!) {
            //var latitude = (marker.objectForKey("latitude") as NSString).doubleValue
            var text = (comment.objectForKey("text") as String)
            var upvotes:Int = (comment.objectForKey("upvotes") as String).toInt()!
            var downvotes:Int = (comment.objectForKey("downvotes") as String).toInt()!
            var created = (comment.objectForKey("created") as String)
            var commentID:Int = (comment.objectForKey("commentID") as String).toInt()!
            var registeredVoted = (comment.objectForKey("registeredVote") as String).toInt()!
            var commentArray: [String: Any] = [
                "text" : text,
                "upvotes" : upvotes,
                "downvotes" : downvotes,
                "created" : created,
                "commentID": commentID,
                "registeredVote": registeredVoted
            ]
            commentsArray.append(commentArray)
        }
        self.numComments = commentsArray.count
        self.commentsArray = commentsArray
        self.commentsArray.sort {
            item1, item2 in
            let vote1 = (item1["upvotes"] as Int) - (item1["downvotes"] as Int)
            let vote2 = (item2["upvotes"] as Int) - (item2["downvotes"] as Int)
            return vote1 > vote2
        }
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func calcTextViewHeight(textView: UITextView) {
        var oldH = textView.frame.size.height
        var fixedWidth = textView.frame.size.width
        var newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, 300.0))
        var newFrame = textView.frame
        newFrame.size = CGSizeMake(fmax(newSize.width, fixedWidth), newSize.height)
        var diffH = newFrame.size.height - oldH
        if (diffH > 8) { // new line
            postCommentView.frame.size.height += diffH
            postCommentView.frame.origin.y -= diffH
            textView.frame = newFrame
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        return countElements(textView.text) + (countElements(text) - range.length) <= 110;
    }
    
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool {
        
        let newLength = countElements(textField.text!) + countElements(string!) - range.length
        return newLength <= 110 //Bool
        
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        placeholder.hidden = true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholder.hidden = false
    }
    
    func textViewDidChange(textView: UITextView) {
        self.calcTextViewHeight(textView)
    }
    
    func keyboardWasShown (notification: NSNotification) {
        let info : NSDictionary = notification.userInfo!
        let keyboardHeight = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().height
        self.view.frame.origin.y = -1*keyboardHeight!
    }
    
    func keyboardWasHidden (notification: NSNotification) {
        let info : NSDictionary = notification.userInfo!
        let keyboardHeight = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().height
        self.view.frame.origin.y = 0
    }
    
    func stringToDate(time:String) -> NSDate {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "PST")
        var createdDate = dateFormatter.dateFromString(time)
        return createdDate!
    }

    func timeDifference(date1:NSDate, date2:NSDate) -> String {
        var calendar : NSCalendar = NSCalendar.currentCalendar()
        var unitFlags : NSCalendarUnit = NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute
        var dateComponent : NSDateComponents = calendar.components(unitFlags, fromDate: date1, toDate: date2, options: nil)
        var timeSince = ((dateComponent.day > 0) ? "\(dateComponent.day) days": ((dateComponent.hour > 0) ? "\(dateComponent.hour) hours" : ((dateComponent.minute > 1) ? "\(dateComponent.minute) minutes" : "0 minutes" )))
        return timeSince
    }
    
    override func viewDidLayoutSubviews() {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> NSInteger {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        // +1 for the original post thats not a comment
        return commentsArray.count + 1
    }
    
    func imageDataFromUrl(url: String) -> NSData? {
        let url = NSURL(string: url)
        var err: NSError?
        var imageData :NSData?
        imageData = NSData(contentsOfURL: url!, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: &err)
        return imageData
    }
    
    func asynchUpdateCellImage(indexPath:NSIndexPath) {
        if let image = ImageCache.sharedManager.imageCache[self.marker_image] {
            dispatch_async(dispatch_get_main_queue(), {
                if let cellToUpdate = self.tableView.cellForRowAtIndexPath(indexPath) as? CommentTableViewCell {
                    cellToUpdate.markerImage?.image = image
                }
            })
        } else {
            // If the image does not exist, we need to download it
            var imgURL: NSURL = NSURL(string: self.marker_image)!
            
            // Download an NSData representation of the image at the URL
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                if error == nil {
                    let image = UIImage(data: data)
                    
                    // Store the image in to our cache
                    ImageCache.sharedManager.imageCache[self.marker_image] = image
                    dispatch_async(dispatch_get_main_queue(), {
                        if let cellToUpdate = self.tableView.cellForRowAtIndexPath(indexPath) as? CommentTableViewCell {
                            cellToUpdate.markerImage?.image = image
                        }
                    })
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
            
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:CommentTableViewCell
        if (indexPath.row == 0) {
            cell = tableView.dequeueReusableCellWithIdentifier("cellHeader", forIndexPath: indexPath) as CommentTableViewCell
            // Set marker image from url
            if (countElements(self.marker_image) > 1) {
                asynchUpdateCellImage(indexPath)
            }
            cell.commentTextView.text = self.text
            cell.time.text = self.timeLeft
            cell.numComments.text = String(self.numComments) + ((self.numComments != 1) ? " Comments" : " Comment")
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as CommentTableViewCell
            var comment = self.commentsArray[indexPath.row - 1]
            cell.commentTextView.text = comment["text"] as String
            cell.commentID = comment["commentID"] as Int
            cell.markerID = self.markerID
            cell.fbid = self.fbid
            cell.voteNumber = (comment["upvotes"] as Int) - (comment["downvotes"] as Int)
            cell.voteCount.text = String(cell.voteNumber)
            cell.voteCount.textColor = UIColorFromRGB(0xEBA536)
            // Set the arrow up/down buttons to blue if they already voted
            cell.registeredVote = comment["registeredVote"] as Int
            if (cell.registeredVote == 1) {
                cell.upButton.setImage(UIImage(named: "arrow-up.png"), forState: .Normal)
            } else if (cell.registeredVote == -1) {
                cell.downButton.setImage(UIImage(named: "arrow-down.png"), forState: .Normal)
            } else {
                cell.upButton.setImage(UIImage(named: "arrow-up-off.png"), forState: .Normal)
                cell.downButton.setImage(UIImage(named: "arrow-down-off.png"), forState: .Normal)
            }
            var createdDate = self.stringToDate(comment["created"] as String)
            var timeSince = "\(self.timeDifference(createdDate, date2: NSDate().dateByAddingTimeInterval(60*60))) ago"
            cell.time.text = timeSince
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 452.0
        } else {
            return 119.0
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
