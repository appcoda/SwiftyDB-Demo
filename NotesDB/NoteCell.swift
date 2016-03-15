//
//  NoteCell.swift
//  NotesDB
//
//  Created by Gabriel Theodoropoulos on 2/20/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class NoteCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var lblCreatedDate: UILabel!
    
    @IBOutlet weak var lblModifiedDate: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
