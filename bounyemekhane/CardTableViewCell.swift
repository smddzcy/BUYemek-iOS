//
//  CardTableViewCell.swift
//  bounyemekhane
//
//  Created by Samed Duzcay on 18/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

import UIKit

class CardTableViewCell : UITableViewCell {
  
  @IBOutlet weak var _cardView: UIView!
  @IBOutlet weak var _imageView: UIImageView! {
    didSet{
      _imageView.layer.cornerRadius = 15
      _imageView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
      _imageView.layer.borderWidth = 1
      _imageView.layer.masksToBounds = true
    }
  }
  @IBOutlet weak var calorieField: UILabel!
  @IBOutlet weak var nameField: UILabel!  
}
