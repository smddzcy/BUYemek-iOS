//
//  DateExtension.swift
//  BUYemek
//
//  Created by Mustafa Enes Cakir on 8/7/17.
//  Copyright © 2017 Samed Duzcay. All rights reserved.
//

import UIKit

extension Date {
  
  init(fromString date:String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    self.init()
    self = formatter.date(from: date)!
  }

  func lastDayOfMonth() -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.month = 1
    components.day = -1
    return calendar.date(byAdding: components, to: self.firstDayOfMonth(), wrappingComponents: false)!
  }
  
  func firstDayOfMonth() -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: self)
    return calendar.date(from: components)!
  }
  
  func toLabel() -> String{
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMMM yyyy"
    formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
    formatter.locale = Locale(identifier: "tr_TR")
    return formatter.string(from: self)
  }

  func toString() -> String{
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY/MM/dd"
    formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
    formatter.locale = Locale(identifier: "tr_TR")
    return formatter.string(from: self)
  }

}
