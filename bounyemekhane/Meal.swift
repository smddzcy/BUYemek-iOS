//
//  Meal.swift
//  bounyemekhane
//
//  Created by Samed Duzcay on 19/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

class Meal{
    
    private var name: String
    private var date: String
    private var meal: Character
    private var calorie: String
    
    init(name: String, meal: Character, date: String){
        self.name = name
        self.meal = meal
        self.date = date
        self.calorie = AppConstants.notAvailableText
    }
    
    init(name: String, meal: Character, date: String, calorie: String){
        self.name = name
        self.meal = meal
        self.date = date
        self.calorie = calorie
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
    
    func getMeal() -> Character{
        return meal
    }
    
    func setMeal(meal: Character) {
        self.meal = meal
    }
    
    func getCalorie() -> String{
        return calorie
    }
    
    func setCalorie(calorie: String) {
        self.calorie = calorie
    }
    
    
    
}
