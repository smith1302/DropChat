//
//  LoadingIndicator.swift
//  DropChat
//
//  Created by Eric Smith on 12/16/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class LoadingIndicator: UIView {
    
    var liArr: Array<UIImageView>!
    var timer: NSTimer!
    var imageView: UIImageView!
    var bgView: UIView!
    var isLoading: Bool = false
    var hasLoaded: Bool = false
    
    func myCustomSetup() {
        self.backgroundColor = UIColor.clearColor() //UIColorFromRGB(0xEAEAEA)
        
        bgView = UIView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        bgView.backgroundColor = UIColorFromRGB(0xEAEAEA)
        
        let liSize:CGFloat = 80.0
        imageView = UIImageView(frame: CGRectMake(frame.size.width/2 - liSize/2, frame.size.height/2 - liSize/2, liSize, liSize))
        imageView.backgroundColor = UIColor.whiteColor()
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = false
        imageView.layer.shadowColor = UIColor.blackColor().CGColor
        imageView.layer.shadowOffset = CGSizeMake(1, 1);
        imageView.layer.shadowRadius = 1
        imageView.layer.shadowOpacity = 0.5
        //
        //        let label = UILabel(frame: CGRectMake(0, 15, frame.size.width, 20))
        //        label.text = "Getting Markers"
        //        label.textAlignment = .Center
        //        label.textColor = UIColor.darkGrayColor()
        //        label.font = UIFont(name: label.font.fontName, size: 15)
        //        imageView.addSubview(label)
        addSubview(bgView)
        bgView.addSubview(imageView)
        
        var padding:CGFloat = 12.0
        var innerPadding:CGFloat = 5
        let size:CGFloat = (liSize/2) - (innerPadding)/2 - padding
        var tSize:CGFloat = (size*2.0)
        var center:CGFloat = padding
        let bColor = UIColorFromRGB(0x6BB5ED)
        var loadIView = UIView(frame: CGRectMake(center, center, tSize, tSize))
        let li1 = UIImageView(frame: CGRectMake(0,0,size,size))
        li1.backgroundColor = bColor
        let li2 = UIImageView(frame: CGRectMake(size+innerPadding,0,size,size))
        li2.backgroundColor = bColor
        let li3 = UIImageView(frame: CGRectMake(0,size+innerPadding,size,size))
        li3.backgroundColor = bColor
        let li4 = UIImageView(frame: CGRectMake(size+innerPadding,size+innerPadding,size,size))
        li4.backgroundColor = bColor
        loadIView.addSubview(li1)
        loadIView.addSubview(li2)
        loadIView.addSubview(li3)
        loadIView.addSubview(li4)
        imageView.addSubview(loadIView)
        
        liArr = [li1,li2,li3,li4]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.myCustomSetup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.myCustomSetup()
    }
    
    func startLoading() {
        if (isLoading) {
            return
        }
        isLoading = true
        self.hidden = false
        self.alpha = 1
        if (timer != nil) {
            timer.invalidate()
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("animateViews:"), userInfo: liArr, repeats: true)
        animateViews(timer)
    }
    
    func stopLoading() {
        if (!isLoading) {
            return
        }
        isLoading = false
        timer.invalidate()
        UIView.animateWithDuration(0.3,
            animations: {
                self.alpha = 0.0
            }, completion: {
                (Bool finished) in
                self.hidden = true
            }
        )
        bgView.backgroundColor = UIColor.clearColor()
        hasLoaded = true
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func animateViews(timer: NSTimer) {
        if let myUserInfo: AnyObject = timer.userInfo {
            var arr:Array<UIImageView> = myUserInfo as Array<UIImageView>
            var li1 = arr[0]
            var li2 = arr[1]
            var li3 = arr[2]
            var li4 = arr[3]
            var smallSize:CGFloat = 0.0000001
            UIView.animateWithDuration(0.3, delay: 0, options: nil, animations: {
                li1.transform = CGAffineTransformMakeScale(1, smallSize)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 0.2, options: nil, animations: {
                li2.transform = CGAffineTransformMakeScale(1, smallSize)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 0.4, options: nil, animations: {
                li3.transform = CGAffineTransformMakeScale(1, smallSize)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 0.6, options: nil, animations: {
                li4.transform = CGAffineTransformMakeScale(1, smallSize)
                }, completion: nil)
            //up
            UIView.animateWithDuration(0.3, delay: 0.8, options: nil, animations: {
                li1.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 1.0, options: nil, animations: {
                li2.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 1.2, options: nil, animations: {
                li3.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: nil)
            UIView.animateWithDuration(0.3, delay: 1.4, options: nil, animations: {
                li4.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: nil)
        }
    }

}
