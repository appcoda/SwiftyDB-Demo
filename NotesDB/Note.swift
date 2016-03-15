//
//  Note.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import SwiftyDB

class ImageDescriptor: NSObject, NSCoding {
    var frameData: NSData!
    var imageName: String!
    
    
    required init?(coder aDecoder: NSCoder) {
        frameData = aDecoder.decodeObjectForKey("frameData") as! NSData
        imageName = aDecoder.decodeObjectForKey("imageName") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(frameData, forKey: "frameData")
        aCoder.encodeObject(imageName, forKey: "imageName")
    }
    
    
    init(frameData: NSData!, imageName: String!) {
        super.init()
        self.frameData = frameData
        self.imageName = imageName
    }
}


class Note: NSObject, Storable {
    let database: SwiftyDB! = SwiftyDB(databaseName: "notes")
    var noteID: NSNumber!
    var title: String!
    var text: String!
    var textColor: NSData!
    var fontName: String!
    var fontSize: NSNumber!
    var creationDate: NSDate!
    var modificationDate: NSDate!
    var images: [ImageDescriptor]!
    var imagesData: NSData!
    
    override required init() {
        super.init()
        
    }
    
    
    func storeNoteImagesFromImageViews(imageViews: [PanningImageView]) {
        if imageViews.count > 0 {
            if images == nil {
                images = [ImageDescriptor]()
            }
            else {
                images.removeAll()
            }
            
            for i in 0..<imageViews.count {
                let imageView = imageViews[i]
                let imageName = "img_\(Int(NSDate().timeIntervalSince1970))_\(i)"
                
                images.append(ImageDescriptor(frameData: imageView.frame.toNSData(), imageName: imageName))
                
                Helper.saveImage(imageView.image!, withName: imageName)
            }
            
            imagesData = NSKeyedArchiver.archivedDataWithRootObject(images)
        }
        else {
            imagesData = NSKeyedArchiver.archivedDataWithRootObject(NSNull())
        }
    }
    
    
    func saveNote(shouldUpdate: Bool = false, completionHandler: (success: Bool) -> Void) {
        database.asyncAddObject(self, update: shouldUpdate) { (result) -> Void in
            if let error = result.error {
                print(error)
                completionHandler(success: false)
            }
            else {
                completionHandler(success: true)
            }
        }
    }
    
    
    func loadAllNotes(completionHandler: (notes: [Note]!) -> Void) {
        database.asyncObjectsForType(Note.self) { (result) -> Void in
            if let notes = result.value {
                completionHandler(notes: notes)
            }
            
            if let error = result.error {
                print(error)
                completionHandler(notes: nil)
            }
        }
    }
    
    
    func loadSingleNoteWithID(id: Int, completionHandler: (note: Note!) -> Void) {
        database.asyncObjectsForType(Note.self, matchingFilter: Filter.equal("noteID", value: id)) { (result) -> Void in
            if let notes = result.value {
                let singleNote = notes[0]
                
                if singleNote.imagesData != nil {
                    singleNote.images = NSKeyedUnarchiver.unarchiveObjectWithData(singleNote.imagesData) as? [ImageDescriptor]
                }
                
                completionHandler(note: singleNote)
            }
            
            if let error = result.error {
                print(error)
                completionHandler(note: nil)
            }
        }
    }
    
    
    func deleteNote(completionHandler: (success: Bool) -> Void) {
        let filter = Filter.equal("noteID", value: noteID)
        
        database.asyncDeleteObjectsForType(Note.self, matchingFilter: filter) { (result) -> Void in
            if let deleteOK = result.value {
                completionHandler(success: deleteOK)
            }
            
            if let error = result.error {
                print(error)
                completionHandler(success: false)
            }
        }
    }
}