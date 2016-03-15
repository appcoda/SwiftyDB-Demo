//
//  Extensions.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import SwiftyDB

extension CGRect {
    func toNSData() -> NSData {
        return NSStringFromCGRect(self).dataUsingEncoding(NSUTF8StringEncoding)!
    }
}


extension NSData {
    func toCGRect() -> CGRect {
        return CGRectFromString(NSString(data: self, encoding: NSUTF8StringEncoding) as! String)
    }
}


extension Note: PrimaryKeys {
    class func primaryKeys() -> Set<String> {
        return ["noteID"]
    }
}


extension Note: IgnoredProperties {
    class func ignoredProperties() -> Set<String> {
        return ["images", "database"]
    }
}