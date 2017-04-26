//
//  MissionTableViewCell.swift
//  GooseBye
//
//  Created by Kishan Patel on 11/11/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit

class MissionTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var nameLabel: UILabel!
    
}
