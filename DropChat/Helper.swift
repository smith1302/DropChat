//
//  Helper.swift
//  DropChat
//
//  Created by Eric Smith on 12/29/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class Helper: NSObject {
    class func makeImageForNavBar(navItem: UINavigationItem, leftOffset: CGFloat) {
        var titleImageView = UIImageView(image: UIImage(named: "small-logo5.fw.png"))
        titleImageView.frame = CGRectMake(leftOffset, 0, 181, 27)
        titleImageView.contentMode = UIViewContentMode.ScaleAspectFit
        navItem.titleView = titleImageView
    }
    
    class func makeImageForNavBar(navItem: UINavigationItem) {
        Helper.makeImageForNavBar(navItem, leftOffset: 0)
    }
}
