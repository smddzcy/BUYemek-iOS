//
//  BUButton.swift
//  BUYemek
//
//  Created by Mustafa Enes Cakir on 8/7/17.
//  Copyright © 2017 Samed Duzcay. All rights reserved.
//

import UIKit

class BUButton: UIButton {
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    layer.cornerRadius = 5
    layer.borderWidth = 1
    layer.borderColor = UIColor.white.cgColor
    self.setTitleColor(UIColor.primaryColor(), for: .highlighted)
  }
}
