//
//  AppConstants.swift
//  BUYemek
//
//  Created by Samed Duzcay on 23/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

import UIKit

struct Constants {
  static let lunchHeaderText: String = "ÖĞLE YEMEĞİ"
  static let dinnerHeaderText: String = "AKŞAM YEMEĞİ"
  static let notAvailableText: String = "NA"
  static let firstDaytoSelect: String = "2016/04/01"
  
  
  struct Paths {
    static let API = "http://www.smddzcy.com/BUYemek/api.php"
    
    static func Menu(date: String) -> String {
      return "\(API)/cafeteria/menu/\(date)"
    }
    
    static func Images(date: String) -> String {
      return "\(API)/cafeteria/images/\(date)"
    }
    
    static func Calories(date: String) -> String {
      return "\(API)/cafeteria/calories/\(date)"
    }
  }

}
