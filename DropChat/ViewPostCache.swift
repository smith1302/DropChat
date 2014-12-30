//
//  ViewPostCache.swift
//  DropChat
//
//  Created by Eric Smith on 12/29/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class ViewPostCache: NSObject {
    // MarkerID : Instance of ViewPostController
    var viewPosts = [Int: ViewPostController]()
    
    class var sharedManager: ViewPostCache {
        struct Static {
            static let instance = ViewPostCache()
        }
        return Static.instance
    }
}
