//
//  NoteListViewController.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class NoteListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditNoteViewControllerDelegate {

    @IBOutlet weak var tblNotes: UITableView!
    
    var notes = [Note]()
    
    var note = Note()
    
    var idOfNoteToEdit: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureTableView()
        
        loadNotes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == "idSegueEditNote" {
                let editNoteViewController = segue.destinationViewController as! EditNoteViewController
                editNoteViewController.delegate = self
                
                if idOfNoteToEdit != nil {
                    editNoteViewController.editedNoteID = idOfNoteToEdit
                    idOfNoteToEdit = nil
                }
            }
        }
    }
    

    
    // MARK: Custom Methods
    
    func configureTableView() {
        tblNotes.delegate = self
        tblNotes.dataSource = self
        tblNotes.registerNib(UINib(nibName: "NoteCell", bundle: nil), forCellReuseIdentifier: "idCellNote")
    }
 
    
    func loadNotes() {
        note.loadAllNotes { (notes) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if notes != nil {
                    self.notes = notes
                    self.sortNotes()
                    self.tblNotes.reloadData()
                }
            })
        }
    }
    
    
    func sortNotes() {
        notes = notes.sort({ (note1, note2) -> Bool in
            let modificationDate1 = note1.modificationDate.timeIntervalSinceReferenceDate
            let modificationDate2 = note2.modificationDate.timeIntervalSinceReferenceDate
            
            return modificationDate1 > modificationDate2
        })
    }
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idCellNote", forIndexPath: indexPath) as! NoteCell
        
        let currentNote = notes[indexPath.row]
        
        cell.lblTitle.text = currentNote.title!
        cell.lblCreatedDate.text = "Created: \(Helper.convertTimestampToDateString(currentNote.creationDate!))"
        cell.lblModifiedDate.text = "Modified: \(Helper.convertTimestampToDateString(currentNote.modificationDate!))"
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        idOfNoteToEdit = notes[indexPath.row].noteID as Int
        performSegueWithIdentifier("idSegueEditNote", sender: self)
    }
 
 
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let noteToDelete = notes[indexPath.row]
            
            noteToDelete.deleteNote({ (success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if success {
                        self.notes.removeAtIndex(indexPath.row)
                        self.tblNotes.reloadData()
                    }
                })
            })
        }
    }
    
    
    // MARK: EditNoteViewControllerDelegate Methods
    
    func didCreateNewNote(noteID: Int) {
        note.loadSingleNoteWithID(noteID) { (note) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if note != nil {
                    self.notes.append(note)
                    self.sortNotes()
                    self.tblNotes.reloadData()
                }
            })
        }
    }
    
    
    
    func didUpdateNote(noteID: Int) {
        var indexOfEditedNote: Int!
        
        for i in 0..<notes.count {
            if notes[i].noteID == noteID {
                indexOfEditedNote = i
                break
            }
        }
        
        if indexOfEditedNote != nil {
            note.loadSingleNoteWithID(noteID, completionHandler: { (note) -> Void in
                if note != nil {
                    self.notes[indexOfEditedNote] = note
                    self.sortNotes()
                    self.tblNotes.reloadData()
                }
            })
        }
    }
}
