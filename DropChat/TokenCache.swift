//
//  TokenCache.swift
//  DropChat
//
//  Created by Eric Smith on 12/29/14.
//  Copyright (c) 2014 Eric Smith. All rights reserved.
//

import UIKit

class TokenCache: NSObject {
    var tokenCache: String = "1302dropchatsignature1302"
    
    class var sharedManager: TokenCache {
        struct Static {
            static let instance = TokenCache()
        }
        return Static.instance
    }
}
