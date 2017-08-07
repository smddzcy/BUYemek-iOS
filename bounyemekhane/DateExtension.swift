//
//  DateExtension.swift
//  BUYemek
//
//  Created by Mustafa Enes Cakir on 8/7/17.
//  Copyright © 2017 Samed Duzcay. All rights reserved.
//

import UIKit

extension Date {
  func lastDayOfMonth() -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.month = 1
    components.day = -1
    return calendar.date(byAdding: components, to: self.firstDayOfMonth(), wrappingComponents: true)!
  }
  
  func firstDayOfMonth() -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: self)
    return calendar.date(from: components)!
  }
}
