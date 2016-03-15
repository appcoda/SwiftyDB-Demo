//
//  Helper.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class Helper: NSObject {
    
    class func loadNoteImageWithName(imageName: String) -> UIImage! {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let imagePath = documentsPath.stringByAppendingString("/\(imageName)")
        
        if NSFileManager.defaultManager().fileExistsAtPath(imagePath) {
            return UIImage(data: NSData(contentsOfFile: imagePath)!)!
        }
        else {
            return nil
        }
    }
    
    
    class func convertTimestampToDateString(timestamp: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy, HH:mm"
        return dateFormatter.stringFromDate(timestamp)
    }
    
    
    class func saveImage(image: UIImage, withName imageName: String!) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        imageData?.writeToFile(documentsPath.stringByAppendingString("/\(imageName)"), atomically: true)
    }
}
