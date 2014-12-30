//
//  ListViewCell.swift
//  DropChat
//
//  Created by Eric Smith on 12/26/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class ListViewCell: UITableViewCell {
    
    var numComments: Int!
    var mainText: String!
    var image_url: String!
    var distance: Double!
    var author: String!
    var rowIndex: Int!
    var tableController: ListViewController!
    var dataIsSet: Bool = false

    @IBOutlet weak var distanceText: UILabel!
    @IBOutlet weak var commentText: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var theImageView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var subBottomView: UIView!
    @IBOutlet weak var nameBar: UIImageView!
    @IBOutlet weak var infoBar: UIImageView!
    @IBOutlet weak var authorNameText: UILabel!
    
    override init() {
        super.init()
        self.customInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.customInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customInit()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.customInit()
    }
    
    func customInit() {
        self.loadingIndicator?.hidden = true
        self.loadingIndicator?.stopAnimating()
    }
    
    override func drawRect(rect: CGRect) {
        self.bgView.layer.cornerRadius = 4
        bgView.layer.borderColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1).CGColor
        bgView.layer.borderWidth = 0.5
        
        theImageView.layer.shadowColor = UIColor.blackColor().CGColor
        theImageView.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        theImageView.layer.shadowOpacity = 0.3
        theImageView.layer.shadowRadius = 1.2
        
        var border = CALayer()
        var width = CGFloat(1.0)
        border.borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1).CGColor
        border.frame = CGRect(x: 0, y: nameBar.frame.size.height - width, width:  nameBar.frame.size.width, height: nameBar.frame.size.height)
        border.borderWidth = width
        nameBar.layer.addSublayer(border)
        nameBar.layer.masksToBounds = true
        
        var oWidth = textView.frame.size.width
        textView.sizeToFit()
        var newFrame = textView.frame
        newFrame.size.width = oWidth
        textView.frame = newFrame
    }
    
    func setData(numComments: Int, text:String, image_url: String, distance: Double, author: String, tableController: ListViewController, rowIndex: Int) {
        // round distance...
        let distanceRounded = Double(round(100*distance)/100)
        self.numComments = numComments
        self.mainText = text
        self.image_url = image_url
        self.distance = distanceRounded
        self.author = author
        self.tableController = tableController
        self.rowIndex = rowIndex
        
        // Set Comments
        commentText.text = (numComments == 1) ? "1 Comment" : "\(numComments) Comments"
        // Set Text
        textView.text = mainText
        textView.scrollEnabled = false
        // Set Distance
        distanceText.text = (distanceRounded == 1) ? "1 Mile" : "\(distanceRounded) Miles"
        // Set Image view
        self.loadingIndicator?.startAnimating()
        self.loadingIndicator?.hidden = false
        asynchUpdateImage(image_url, imageView: self.theImageView!)
        // Set Author
        self.authorNameText.text = author
        
        self.dataIsSet = true
    }
    
    func asynchUpdateImage(url:String, imageView: UIImageView) {
        if let image = ImageCache.sharedManager.imageCache[url] {
            dispatch_async(dispatch_get_main_queue(), {
                imageView.image = image
                self.loadingIndicator?.stopAnimating()
                self.loadingIndicator?.hidden = true
            })
        } else {
            // If the image does not exist, we need to download it
            var imgURL: NSURL = NSURL(string: url)!
            // Download an NSData representation of the image at the URL
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                if error == nil {
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadingIndicator?.stopAnimating()
                        self.loadingIndicator?.hidden = true
                        ImageCache.sharedManager.imageCache[url] = image
                        imageView.image = image
                    })
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
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
