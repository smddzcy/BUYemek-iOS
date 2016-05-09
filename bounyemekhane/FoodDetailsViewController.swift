//
//  FoodDetailsViewController.swift
//  bounyemekhane
//
//  Created by Samed Duzcay on 21/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

import UIKit

class FoodDetailsViewController: UIViewController {

    @IBOutlet weak var _imageView: UIImageView!
    @IBOutlet weak var calorieField: UILabel!
    @IBOutlet weak var nameField: UILabel!

    var name: String = ""
    var calories: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(animated: Bool) {
        calorieField.text = calories
        nameField.text = name
        self.title = name
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
