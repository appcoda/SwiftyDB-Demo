//
//  EditNoteViewController.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

protocol EditNoteViewControllerDelegate {
    func didCreateNewNote(noteID: Int)
    
    func didUpdateNote(noteID: Int)
}


class EditNoteViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PanningImageViewDelegate {

    @IBOutlet weak var txtTitle: UITextField!
    
    @IBOutlet weak var tvNote: UITextView!
    
    
    var delegate: EditNoteViewControllerDelegate!
    
    var imageViews = [PanningImageView]()
    
    var currentFontName = "Helvetica Neue"
    
    var currentFontSize: CGFloat = 15.0
    
    var editedNoteID: Int!
    
    var editedNote = Note()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Down
        view.addGestureRecognizer(swipeGestureRecognizer)
        
        
        configureNavBar()
        configureTextView()
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if editedNoteID != nil {
            editedNote.loadSingleNoteWithID(editedNoteID, completionHandler: { (note) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if note != nil {
                        self.txtTitle.text = note.title!
                        self.tvNote.text = note.text!
                        self.tvNote.textColor = NSKeyedUnarchiver.unarchiveObjectWithData(note.textColor!) as? UIColor
                        self.tvNote.font = UIFont(name: note.fontName!, size: note.fontSize as CGFloat)
                        
                        if let images = note.images {
                            for image in images {
                                let imageView = PanningImageView(frame: image.frameData.toCGRect())
                                imageView.image = Helper.loadNoteImageWithName(image.imageName)
                                imageView.delegate = self
                                self.tvNote.addSubview(imageView)
                                self.imageViews.append(imageView)
                                self.setExclusionPathForImageView(imageView)
                            }
                        }
                        
                        self.editedNote = note
                        
                        self.currentFontName = note.fontName!
                        self.currentFontSize = note.fontSize as CGFloat
                    }
                })
            })
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: Custom Methods
    
    func configureNavBar() {
        let saveBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "saveNote")
        navigationItem.rightBarButtonItem = saveBarButton
    }
    
    
    func configureTextView() {
        tvNote.textColor = UIColor.blackColor()
        tvNote.font = UIFont(name: currentFontName, size: currentFontSize)
        tvNote.contentInset = UIEdgeInsetsMake(-55.0, 0.0, 0.0, 0.0)
    }

    
    func importPhotoFromSourceType(sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = sourceType
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func setExclusionPathForImageView(imageView: PanningImageView) {
        var bezierPaths = [UIBezierPath]()
        for imageView in imageViews {
            bezierPaths.append(UIBezierPath(rect: imageView.frame))
        }
        tvNote.textContainer.exclusionPaths = bezierPaths
    }
    
    
    func dismissKeyboard() {
        if txtTitle.isFirstResponder() {
            txtTitle.resignFirstResponder()
        }
        
        if tvNote.isFirstResponder() {
            tvNote.resignFirstResponder()
        }
    }
    
    
    func saveNote() {
        if txtTitle.text?.characters.count == 0 || tvNote.text.characters.count == 0 {
            return
        }
        
        if tvNote.isFirstResponder() {
            tvNote.resignFirstResponder()
        }
        
        let note = (editedNoteID == nil) ? Note() : editedNote
        
        if editedNoteID == nil {
            note.noteID = Int(NSDate().timeIntervalSince1970)
            note.creationDate = NSDate()
        }
        note.title = txtTitle.text
        note.text = tvNote.text!
        note.textColor = NSKeyedArchiver.archivedDataWithRootObject(tvNote.textColor!)
        note.fontName = tvNote.font?.fontName
        note.fontSize = tvNote.font?.pointSize
        note.modificationDate = NSDate()
        
        note.storeNoteImagesFromImageViews(imageViews)
        
        let shouldUpdate = (editedNoteID == nil) ? false : true
        
        note.saveNote(shouldUpdate) { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if success {
                    if self.delegate != nil {
                        if !shouldUpdate {
                            self.delegate.didCreateNewNote(note.noteID as Int)
                        }
                        else {
                            self.delegate.didUpdateNote(self.editedNoteID)
                        }
                    }
                    self.navigationController?.popViewControllerAnimated(true)
                }
                else {
                    let alertController = UIAlertController(title: "NotesDB", message: "An error occurred and the note could not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                        
                    }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            })
        }
    }
    
    
    
    // MARK: IBAction Methods
    
    @IBAction func insertPicture(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let savedPhotosAction = UIAlertAction(title: "From Photos", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.importPhotoFromSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
        }
        
        let cameraAction = UIAlertAction(title: "From Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.importPhotoFromSourceType(UIImagePickerControllerSourceType.Camera)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            
        }
        
        actionSheet.addAction(savedPhotosAction)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(cancelAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func changeTextColor(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let blackColor = UIAlertAction(title: "Black", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.textColor = UIColor.blackColor()
        }
        
        let redColor = UIAlertAction(title: "Red", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.textColor = UIColor.redColor()
        }
        
        let blueColor = UIAlertAction(title: "Blue", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.textColor = UIColor.blueColor()
        }
        
        let orangeColor = UIAlertAction(title: "Orange", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.textColor = UIColor.orangeColor()
        }
        
        let brownColor = UIAlertAction(title: "Brown", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.textColor = UIColor.brownColor()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            
        }
        
        actionSheet.addAction(blackColor)
        actionSheet.addAction(redColor)
        actionSheet.addAction(blueColor)
        actionSheet.addAction(orangeColor)
        actionSheet.addAction(brownColor)
        actionSheet.addAction(cancelAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func changeFontName(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let font1 = UIAlertAction(title: "Helvetica Neue", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: "Helvetica Neue", size: self.currentFontSize)
            self.currentFontName = "Helvetica Neue"
        }
        
        let font2 = UIAlertAction(title: "Futura", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: "Futura", size: self.currentFontSize)
            self.currentFontName = "Futura"
        }
        
        let font3 = UIAlertAction(title: "Noteworthy", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: "Noteworthy", size: self.currentFontSize)
            self.currentFontName = "Noteworthy"
        }
        
        let font4 = UIAlertAction(title: "Papyrus", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: "Papyrus", size: self.currentFontSize)
            self.currentFontName = "Papyrus"
        }
        
        let font5 = UIAlertAction(title: "Georgia", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: "Georgia", size: self.currentFontSize)
            self.currentFontName = "Georgia"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            
        }
        
        actionSheet.addAction(font1)
        actionSheet.addAction(font2)
        actionSheet.addAction(font3)
        actionSheet.addAction(font4)
        actionSheet.addAction(font5)
        actionSheet.addAction(cancelAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func changeFontSize(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let font1 = UIAlertAction(title: "12.0", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: self.currentFontName, size: 12.0)
            self.currentFontSize = 12.0
        }
        
        let font2 = UIAlertAction(title: "15.0", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: self.currentFontName, size: 15.0)
            self.currentFontSize = 15.0
        }
        
        let font3 = UIAlertAction(title: "18.0", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: self.currentFontName, size: 18.0)
            self.currentFontSize = 18.0
        }
        
        let font4 = UIAlertAction(title: "21.0", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: self.currentFontName, size: 21.0)
            self.currentFontSize = 21.0
        }
        
        let font5 = UIAlertAction(title: "28.0", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.tvNote.font = UIFont(name: self.currentFontName, size: 28.0)
            self.currentFontSize = 28.0
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            
        }
        
        actionSheet.addAction(font1)
        actionSheet.addAction(font2)
        actionSheet.addAction(font3)
        actionSheet.addAction(font4)
        actionSheet.addAction(font5)
        actionSheet.addAction(cancelAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            var width: CGFloat!
            var height: CGFloat!
            let ratio = selectedImage.size.width / selectedImage.size.height
            
            if selectedImage.size.height > selectedImage.size.width {
                height = 200.0
                width = ratio * height
            }
            else {
                width = 200.0
                height = width / ratio
            }
            
            UIGraphicsBeginImageContext(CGSizeMake(width, height))
            selectedImage.drawInRect(CGRectMake(0, 0, width, height))
            let smallImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let imageView = PanningImageView(frame: CGRectMake(0.0, 0.0, width, height))
            imageView.image = smallImage
            imageView.delegate = self
            tvNote.addSubview(imageView)
            
            imageViews.append(imageView)
            setExclusionPathForImageView(imageView)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: PanningImageViewDelegate Methods
    
    func didMoveImageView(sender: PanningImageView) {
        setExclusionPathForImageView(sender)
    }
}
