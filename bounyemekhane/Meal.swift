//
//  Meal.swift
//  bounyemekhane
//
//  Created by Samed Duzcay on 19/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

import UIKit

class Meal{
    
    private var name: String
    private var date: String
    private var meal: String
    private var calorie: String
    private var imageViews: [UIImageView]
    
    convenience init(name: String, meal: String, date: String){
        self.init(name: name,meal: meal,date: date, calorie: AppConstants.notAvailableText)
    }
    
    init(name: String, meal: String, date: String, calorie: String){
        self.name = name
        self.meal = meal
        self.date = date
        self.calorie = calorie
        self.imageViews = []
    }
    
    func getName() -> String{
        return name
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    func getDate() -> String{
        return date
    }
    
    func setDate(date: String) {
        self.date = date
    }
    
    func getMeal() -> String{
        return meal
    }
    
    func setMeal(meal: String) {
        self.meal = meal
    }
    
    func getCalorie() -> String{
        return calorie
    }
    
    func setCalorie(calorie: String) {
        self.calorie = calorie
    }
    
    func getImageViews() -> [UIImageView]{
        return self.imageViews
    }
    
    func setImageView(imageView: UIImageView, atIndex: Int){
        if atIndex < self.imageViews.endIndex{
            self.imageViews.removeAtIndex(atIndex)
        }
        self.imageViews.insert(imageView, atIndex: atIndex)
    }
    
    
    
}
