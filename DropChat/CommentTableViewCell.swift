//
//  CommentTableViewCell.swift
//  DropChat
//
//  Created by Eric Smith on 12/5/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    var commentID: Int!
    var fbid:String!
    var markerID:Int!
    var vps:ViewPostService = ViewPostService()
    var voteNumber:Int = 0
    var registeredVote:Int = 0
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var markerImage: UIImageView!
    @IBOutlet weak var voteCount: UILabel!
    @IBOutlet weak var time: UILabel!
    
    @IBOutlet weak var numComments: UILabel!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var voteView: UIView!
    
    @IBAction func upClick(sender: UIButton) {
        // If we already voted return
        if (registeredVote != 0) {
            return
        }
        vps.vote(1, fbid: fbid, commentID: commentID, markerID: markerID, voteReceived: voteReceived)
    }
    
    @IBAction func downClick(sender: UIButton) {
        // If we already voted return
        if (registeredVote != 0) {
            return
        }
        vps.vote(-1, fbid: fbid, commentID: commentID, markerID: markerID, voteReceived: voteReceived)
    }
    
    @IBAction func clicky(sender: AnyObject) {
    }
    
    func voteReceived(data:NSDictionary) {
        var success = data["success"] as Int
        if (success == 1) {
            var vote:Int = (data["message"] as String).toInt()!
            voteNumber += (vote as Int)
            // Create our temp label to slide down
            var voteCountFrame = voteCount.frame
            voteCountFrame.origin.y -= 50
            var temp = UILabel(frame: voteCountFrame)
            voteView.addSubview(temp)
            temp.text = String(voteNumber)
            temp.textAlignment = .Center
            temp.font = voteCount.font
            temp.textColor = voteCount.textColor
            var tempGoalFrame = voteCount.frame
            UIView.animateWithDuration(0.3,
                animations: {
                    temp.frame = tempGoalFrame
                    self.voteCount.transform = CGAffineTransformMakeTranslation(0, 100)
                }, completion: {
                    (Bool finished) in
                    if (finished) {
                        self.voteCount.removeFromSuperview()
                        self.voteCount = temp
                    }
                }
            )
            
            self.registeredVote += (vote as Int)
            voteCount.text = String(voteNumber)
            if (vote > 0) {
                upButton.setImage(UIImage(named: "arrow-up.png"), forState: .Normal)
            } else {
                downButton.setImage(UIImage(named: "arrow-down.png"), forState: .Normal)
            }
        } else {
            println("Already voted")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
