//
//  CustomAnnotationView.swift
//  DropChat
//
//  Created by Eric Smith on 12/4/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit
import MapKit
import SpriteKit

class CustomAnnotationView: MKAnnotationView {
    
    var marker_user_image: String = ""
    var marker_image: String!
    var marker_image_view: UIImageView!
    var isAuthor: Bool = false
    var hasViewed: Bool = false
    var coordinate: CLLocationCoordinate2D!
    var text: String!
    var markerID: Int!
    var authorID: String!
    var author_name: String!
    var created: String!
    var numComments: Int!
    var hasDrawn: Bool = false
    var previewView: UIImageView!
    
    var mapView:MKMapView!
    var selfView: MapViewController!
    var markerImage: UIImage!
    var userImageView: UIImageView!
    var textLabel: UILabel!
    var markerIV: UIImageView!
    var circleImage: UIImageView!
    var xButton:UIImageView!
    var xButtonLabel: UILabel!
    
    var showPreviewTimer: NSTimer!
    var circleView: CircleView?
    var w:CGFloat = 50.5
    var h:CGFloat = 63
    let offset:CGFloat = 16.0
    
    override init() {
      super.init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init!(annotation: MKAnnotation!, reuseIdentifier: String!, selfView:MapViewController) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.selfView = selfView
        self.mapView = selfView.mapView
    }
    
    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setMarkerData(coordinate:CLLocationCoordinate2D, markerData: NSDictionary) {
        var marker_user_image = markerData.objectForKey("marker_user_image") as String
        var marker_image = markerData.objectForKey("image_url") as String
        var text = markerData.objectForKey("text") as String
        var isAuthor = markerData.objectForKey("isAuthor") as String
        var isAuthorBool = (isAuthor == "1" ? true : false)
        var hasViewed = markerData.objectForKey("hasViewed") as String
        var hasViewedBool = (hasViewed == "1" ? true : false)
        var authorID = markerData.objectForKey("authorID") as String
        var markerID = (markerData.objectForKey("markerID") as String).toInt()
        var author_name = markerData.objectForKey("author_name") as String
        var created = markerData.objectForKey("created") as String
        var numComments = (markerData.objectForKey("numComments") as String).toInt()
        
        self.coordinate = coordinate
        self.marker_user_image = marker_user_image
        self.isAuthor = isAuthorBool
        self.hasViewed = hasViewedBool
        self.text = text
        self.markerID = markerID
        self.authorID = authorID
        self.marker_image = marker_image
        self.author_name = author_name
        self.created = created
        self.numComments = numComments
        
        // Prepare image to be seen on long press
        // just need:
        // addSubView(marker_image_view) 
        // to show
//        var image:UIImage!
//        if (self.selfView?.imageCache[self.marker_image] == nil) {
//            if let imageData = self.imageDataFromUrl(marker_image) {
//                image = UIImage(data: imageData)!
//                //self.selfView.imageCache[self.marker_image] = image
//            }
//        }
        
        let imageSize:CGFloat = 200
        let padding:CGFloat = 7
        previewView = UIImageView(frame: CGRectMake((-1*imageSize)/2 + (w+offset)/2, -1*imageSize, imageSize, imageSize))
        previewView.backgroundColor = UIColor.whiteColor()
        previewView.layer.cornerRadius = 5
        //            previewView.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).CGColor
        //            previewView.layer.borderWidth = 1
        previewView.layer.shadowColor = UIColor.blackColor().CGColor
        previewView.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        previewView.layer.shadowOpacity = 0.5
        previewView.layer.shadowRadius = 1.0
        marker_image_view = UIImageView(frame: CGRectMake(padding, padding, imageSize-padding*2, imageSize-padding*2))
        asynchUpdateImage(self.marker_image, imageView: marker_image_view)
        var xButtonSize:CGFloat = 40
        xButton = UIImageView(frame: CGRectMake(previewView.frame.size.width - xButtonSize + 10, -10, xButtonSize, xButtonSize))
        xButton.backgroundColor = UIColor.whiteColor()
        xButton.layer.cornerRadius = xButtonSize/2.0
        //xButton.layer.borderWidth = 2
        //xButton.layer.borderColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).CGColor
        xButtonLabel = UILabel(frame: CGRectMake((xButtonSize - 15)/2,(xButtonSize - 15)/2 - 1.5,15,15))
        xButtonLabel.textColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        xButtonLabel.text = "x"
        xButtonLabel.textAlignment = .Center
        xButton.addSubview(xButtonLabel)
        previewView.addSubview(marker_image_view)
        previewView.addSubview(xButton)
        previewView.bringSubviewToFront(xButton)
        
    }
    
    func setNumComments(numComments:Int) {
        if (self.numComments != numComments) {
            self.numComments = numComments
            textLabel.text = String(numComments)
        }
    }
    
    func addCircleView(x : CGFloat, y : CGFloat) {
        var circleWidth = CGFloat(100)
        var circleHeight = circleWidth
        var rx = x - circleWidth/2
        var ry = y - circleHeight/2
        circleView = CircleView(frame: CGRectMake(rx, ry, circleWidth, circleHeight))
        addSubview(circleView!)
        circleView!.animateCircle(1.0)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        // Expanding circle
//        let imageView = UIImageView(frame: CGRectMake(bounds.origin.x + w/4, bounds.origin.y + h/4, 30, 30))
//        imageView.transform = CGAffineTransformMakeScale(8, 8)-
//        imageView.layer.cornerRadius = 15
//        imageView.backgroundColor = UIColor(red: 1, green: 92.0/255.0, blue: 0, alpha: 0.5)
//        UIView.animateWithDuration(2, animations: {
//            imageView.transform = CGAffineTransformMakeScale(1, 1)
//            imageView.alpha = 0
//            imageView.removeFromSuperview()
//        })
//        addSubview(imageView)
//        sendSubviewToBack(imageView)
        
        // Scale marker size
        self.showPreviewTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("showPreview"), userInfo: nil, repeats: true)
        UIView.animateWithDuration(0.2, animations: {
                self.transform = CGAffineTransformMakeScale(1.15, 1.15)
            }
        )
        
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.touchDidEndOrCancel(touches)
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        self.touchDidEndOrCancel(touches)
    }
    
    func touchDidEndOrCancel (touches: NSSet) {
        // We released before the wait time, so stop preview from showing
        showPreviewTimer?.invalidate()
        showPreviewTimer = nil
        self.layer.removeAllAnimations()
        self.previewView.layer.removeAllAnimations()
        // When the preview has ended, check if we should show detail view or not
        if let touchPoint:CGPoint = touches.anyObject()?.locationInView(self) as CGPoint? {
            var convP = self.convertPoint(touchPoint, toView: xButton)
            if (CGRectContainsPoint(xButton.bounds, convP)) {
                var alert = UIAlertController(title: "Drop Chat", message: "Are you sure you wish to hide this marker?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: deleteMarker))
                alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil))
                self.selfView.presentViewController(alert, animated: true, completion: nil)
            } else if (CGRectContainsPoint(self.bounds, touchPoint)) {
                // Released inside annotation
                self.selfView.openViewPost(self)
            }
        }
        
        // Zoom the preview back in
        UIView.animateWithDuration(0.2,
            animations: {
                self.transform = CGAffineTransformMakeScale(1, 1)
                self.previewView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.2, 0.2), CGAffineTransformMakeTranslation(0, 80))
                self.previewView.alpha = 0.01
            }, completion: {(Bool) in
                self.previewView.removeFromSuperview()
            }
        )
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if let touchPoint:CGPoint = touches.anyObject()?.locationInView(self) as CGPoint? {
            var convP = self.convertPoint(touchPoint, toView: xButton)
            var convP2 = self.convertPoint(touchPoint, toView: previewView)
            if (CGRectContainsPoint(xButton.bounds, convP)) {
                xButton.backgroundColor = UIColor(red: 220/255.0, green: 220/255.0, blue: 220/255.0, alpha: 1.0)
                self.xButton.transform = CGAffineTransformMakeScale(1.2, 1.2)
            } else {
                self.xButton.transform = CGAffineTransformMakeScale(1, 1)
                xButton.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    func deleteMarker(alert: UIAlertAction!){
        self.selfView?.ms.hideMarker(self.selfView.fbid, markerID: self.markerID)
        self.mapView.removeAnnotation(annotation)
        self.selfView?.markerDictionary[self.markerID] = nil
        self.selfView?.markersThatExist[markerID] = nil
    }
    
    func showPreview() {
        showPreviewTimer.invalidate()
        showPreviewTimer = nil
        // Preview
        self.addSubview(self.previewView)
        self.previewView.alpha = 0.1
        self.previewView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.2, 0.2), CGAffineTransformMakeTranslation(0, 80))
        UIView.animateWithDuration(0.2,
            animations: {
                self.previewView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(1, 1), CGAffineTransformMakeTranslation(0, 0))
                self.previewView.alpha = 1
            }
        )
    }
    
    func setHasViewed(hasViewed: Bool) {
        // If its not changing we dont have to worry about updating the image etc
        if (self.hasViewed == hasViewed) {
            return
        }
        self.hasViewed = hasViewed
        if (hasViewed && !isAuthor) {
            markerImage = UIImage(named: "marker-seen.png")
            markerIV.image = markerImage
            circleImage.backgroundColor = UIColor(red: 136/255.0, green: 146/255.0, blue: 136.0/255.0, alpha: 1) // gray
        }
    }

    override func drawRect(rect: CGRect) {
        // Prevent drawing twice. For some reason this would get called again sometimes and the frame would be differen't cause some strange offsets
        if (hasDrawn) {
            return
        }
        
        let rightY = self.frame.size.width
        self.frame = CGRectMake(0, 0, w+offset, h+offset)
        markerIV = UIImageView(frame: CGRectMake(offset/2, offset/2, w, h))
        if (self.isAuthor) {
            markerImage = UIImage(named: "marker-owner.png")
        } else if (self.hasViewed) {
            markerImage = UIImage(named: "marker-seen.png")
        } else {
            markerImage = UIImage(named: "marker-normal.png")
        }
        //markerImage?.drawAtPoint(CGPointMake(0, 0))
        //markerImage?.drawInRect(CGRectMake(0, 0, 44, 56))
        markerIV.image = markerImage
        self.addSubview(markerIV)
        
        // Our user profile image
        userImageView = UIImageView(frame: CGRectMake((offset/2) + 4.8, (offset/2) + 5.7, 40.5, 40.5))
        userImageView.clipsToBounds = true;
        userImageView.layer.cornerRadius = 19
        // Do this asynch to make loading quicker
        asynchUpdateImage(self.marker_user_image, imageView: userImageView)
        self.addSubview(userImageView)
        
        let radius:CGFloat = 12.0
        textLabel = UILabel(frame: CGRectMake((rightY - 4.1) + 1, (5.2) + 1, radius*2, 15))
        textLabel.textAlignment = .Center
        textLabel.text = String(self.numComments)
        textLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 12.0)
        textLabel.textColor = UIColor.whiteColor()
        self.addSubview(textLabel)
        
        // draw a circle
        circleImage = UIImageView(frame: CGRectMake((rightY - (radius/2) + 2) + 1, (radius/2 - 5) + 1, radius*2, radius*2))
        circleImage.layer.cornerRadius = radius
        circleImage.layer.shadowColor = UIColor.blackColor().CGColor
        circleImage.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        circleImage.layer.shadowOpacity = 0.4
        circleImage.layer.shadowRadius = 1.0
        self.addSubview(circleImage)
        self.bringSubviewToFront(textLabel)
        circleImage.backgroundColor = UIColor.redColor()
        if (self.isAuthor) {
            circleImage.backgroundColor = UIColor(red: 66.0/255.0, green: 171.0/255.0, blue: 227.0/255.0, alpha: 1) // blue
        } else if (self.hasViewed) {
            circleImage.backgroundColor = UIColor(red: 136/255.0, green: 146/255.0, blue: 136.0/255.0, alpha: 1) // gray
        } else {
            circleImage.backgroundColor = UIColor(red: 255/255.0, green: 147/255.0, blue: 38/255.0, alpha: 1)
        }
        hasDrawn = true
    }
    
    // HELPER METHODS
    
    func asynchUpdateImage(url:String, imageView: UIImageView) {
        if let image = ImageCache.sharedManager.imageCache[url] {
            dispatch_async(dispatch_get_main_queue(), {
                imageView.image = image
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

}


class CircleView: UIView {
    let circleLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        
        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: 0.0, endAngle: CGFloat(M_PI * 2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.strokeColor = UIColor(red: 109/255.0, green: 205/255.0, blue: 237/255.0, alpha: 1).CGColor
        circleLayer.lineWidth = 5.0;
        
        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func animateCircle(duration: NSTimeInterval) {
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration
        
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = 0
        animation.toValue = 1
        
        // Do a linear animation (i.e. the speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // right value when the animation ends.
        circleLayer.strokeEnd = 1.0
        
        // Do the actual animation
        circleLayer.addAnimation(animation, forKey: "animateCircle")
    }
    
}