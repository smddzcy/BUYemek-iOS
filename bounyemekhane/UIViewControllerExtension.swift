//
//  UIViewControllerExtension.swift
//  BUYemek
//
//  Created by Mustafa Enes Cakir on 8/7/17.
//  Copyright © 2017 Samed Duzcay. All rights reserved.
//

import UIKit
import MBProgressHUD


extension UIViewController {
  
  func showAlert(title:String, message:String, completion: @escaping ()->()) {
    let alert = UIAlertController(title: title, message: message, preferredStyle:.alert)
    alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: {UIAlertAction in completion()}))
    self.present(alert, animated: true, completion: nil)
  }
  
  func showHUD(_ text:String){
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.label.text = text
  }
  
  func hideHUD(){
    MBProgressHUD.hide(for: self.view, animated: true)
  }
  
}

