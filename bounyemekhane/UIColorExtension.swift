//
//  UIColorExtension.swift
//  BUYemek
//
//  Created by Mustafa Enes Cakir on 8/7/17.
//  Copyright © 2017 Samed Duzcay. All rights reserved.
//

import UIKit

extension UIColor {
  
  
  convenience init(fromHex hex:String) {
    var cString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
    
    if cString.hasPrefix("#"){
      cString = (cString as NSString).substring(from: 1)
    }
    
    if cString.characters.count != 6 {
      self.init(white: 0.5, alpha: 1)
      return
    }
    
    var rgbValue :UInt32 = 0
    
    Scanner(string: cString).scanHexInt32(&rgbValue)
    
    self.init(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1)
    )
  }

  func toImage() -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
    self.setFill()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }
  
  static func primaryColor() -> UIColor {
    return UIColor(red: 119/255.0, green: 199/255.0, blue: 253/255.0, alpha: 1)
  }

}
