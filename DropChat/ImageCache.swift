//
//  ImageCache.swift
//  DropChat
//
//  Created by Eric Smith on 12/27/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class ImageCache: NSObject {
    var imageCache = [String: UIImage]()
    
    class var sharedManager: ImageCache {
        struct Static {
            static let instance = ImageCache()
        }
        return Static.instance
    }
}
