//
//  CardTableViewController.swift
//  bounyemekhane
//
//  Created by Samed Duzcay on 18/04/16.
//  Copyright © 2016 Samed Duzcay. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import Kingfisher
import ActionSheetPicker_3_0

class CardTableViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet var _tableView: UITableView!
  @IBOutlet weak var dateField: UILabel!
  
  // MARK: - Properties
  private var date:Date = Date()
  var cachedMeals = [NSManagedObject]()
  var lunchFoods: [Meal] = []
  var dinnerFoods: [Meal] = []
  var imagePaths: NSDictionary = NSDictionary()
  
  
  // MARK: - Lifecycles
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dateField.text = self.date.toLabel()
    getFoodList(date: self.date.toString())
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: - IBActions
  @IBAction func selectDatePressed(sender: UIButton) -> Void {
    let datePicker = ActionSheetDatePicker(title: "Tarih:", datePickerMode: .date, selectedDate: self.date,
        doneBlock: { picker, value, index in
          self.date = value as! Date
          self.dateField.text = self.date.toLabel()
          self.getFoodList(date: self.date.toString())
          return
        }, cancel: { ActionStringCancelBlock in return }, origin: sender.superview!.superview)
    datePicker?.locale = Locale(identifier: "tr")
    datePicker?.minimumDate = Date(fromString: Constants.firstDaytoSelect) // started storing data on April 1st
    datePicker?.maximumDate = Date().lastDayOfMonth()
    datePicker?.show()
  }
  
  // MARK: - Helpers
  /**
   Parses JSON data
   
   - parameter inputData: NSData to be parsed into JSON (represented as NSDictionary)
   
   - returns: JSON data (represented as NSDictionary)
   */
  func parseJSON(inputData: NSData) -> NSDictionary{
    do {
      let boardsDictionary: NSDictionary = try JSONSerialization.jsonObject(with: inputData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
      return boardsDictionary
    } catch { }
    return NSDictionary()
  }
  
  /**
   Gets image for the meal, loads it asynchronously and puts it as a UIIMageView in given meal's imageViews array
   
   - parameter meal: Meal to handle the image
   */
  func handleImageForFood(meal: Meal){
    // initialize the "no image" image view
    meal.setImageView(imageView: UIImageView(image: UIImage(named: "noImage")), atIndex: 0)
    
    // if not nil, then its a multiple food line
    var imageURL = self.imagePaths.value(forKey: meal.getName()) as? NSArray
    if imageURL == nil && self.imagePaths.value(forKey: meal.getName()) != nil{ // single url
      imageURL = [String(describing: self.imagePaths.value(forKey: meal.getName())!)]
    }
    
    // set images & download them asynchronously
    if (imageURL != nil){
      var j: Int = 0
      for url in imageURL! {
        let imagePart = UIImageView()
        imagePart.image = UIImage(named: "noImage")
        meal.setImageView(imageView: imagePart, atIndex: j)
        if url as? String != nil {
          if let urlObj = URL(string: url as! String){
            imagePart.kf.setImage(with: urlObj)
          }
        }
        j+=1
      }
      
    }
  }
  
  
  /**
   Gets food list from local storage or server (if local storage fails)
   
   - parameter date: Date to get the food list
   */
  func getFoodList(date: String){
    
    // no need to get the food list from server if it already exists on local storage
    if getMealsFromLocalStorage(date: date) {
      return
    }
    
    lunchFoods = []
    dinnerFoods = []
    self._tableView.reloadData()
    
    self.showHUD("Yükleniyor")
    
    Alamofire.request(Constants.Paths.Menu(date: date))
      .validate()
      .responseJSON { response in
        if response.result.isFailure {
          self.hideHUD()
          self.showAlert(title: "Hata", message: "Sunucuyla bağlantı kurulamadı.", completion: {})
        }else{
          let foodList: NSDictionary = response.result.value as! NSDictionary
          
          Alamofire.request(Constants.Paths.Calories(date: date))
            .validate()
            .responseJSON {response2 in
              
              let calorieList: NSDictionary = response2.result.value as! NSDictionary
              if let lunch = foodList.value(forKey: "lunch") as? [String] {
                let dinner = foodList.value(forKey: "dinner") as? [String]
                if lunch.count > 0 && dinner != nil && dinner!.count > 0{
                  for i in lunch{
                    let meal: Meal = Meal(name: i, meal: "L", date: date)
                    if let calorie = calorieList.value(forKey: i) {
                      meal.setCalorie(calorie: "\(calorie)")
                    }
                    self.saveMealToLocalStorage(meal: meal)
                    self.lunchFoods.append(meal)
                  }
                  for i in dinner!{
                    let meal: Meal = Meal(name: i, meal: "D", date: date)
                    if let calorie = calorieList.value(forKey: i) {
                      meal.setCalorie(calorie: "\(calorie)")
                    }
                    self.saveMealToLocalStorage(meal: meal)
                    self.dinnerFoods.append(meal)
                  }
                } else {
                  self.showAlert(title: "Üzgünüz", message: "Seçilen gün için yemek servisi bulunmamaktadır.", completion: {})
                }
                
                // remove the indicator
                self.hideHUD()
                self._tableView.reloadData()
                self.getFoodImages(date: date)
              }
          }
        }
    }
    
  }
  
  
  /**
   Gets image paths from server and handles images for all foods
   
   - parameter date: Date to get the image list
   */
  func getFoodImages(date: String){
    // get all images for the day
    Alamofire.request(Constants.Paths.Images(date: date))
      .validate()
      .responseJSON { response in
        if response.result.value != nil{
          self.imagePaths = response.result.value as! NSDictionary
        }
        for meal in self.lunchFoods+self.dinnerFoods{
          self.handleImageForFood(meal: meal)
        }
        self._tableView.reloadData()
    }
  }
  
  /**
   Fetchs local storage and puts them into `cachedMeals`
   */
  func fetchLocalStorage(){
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let managedContext = appDelegate.managedObjectContext
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Meal")
    
    do {
      let results = try managedContext.fetch(fetchRequest)
      cachedMeals = results as! [NSManagedObject]
    } catch { }
  }
  
  
  /**
   Gets food list from local storage for given date
   
   - parameter date: Date to get the food list
   
   - returns: True if there are meals on local storage for given date, false otherwise
   */
  func getMealsFromLocalStorage(date: String) -> Bool{
    
    fetchLocalStorage()
    
    lunchFoods = []
    dinnerFoods = []
    _tableView.reloadData()
    
    var mealsInLocalStorage: Bool = false
    for meal in cachedMeals{
      if let mealDate = meal.value(forKey: "date") as? String{
        if mealDate == date{
          if meal.value(forKey: "meal") as! String == "L" {
            let _meal = Meal(name: meal.value(forKey: "name") as! String, meal: "L", date: meal.value(forKey: "date") as! String, calorie: meal.value(forKey: "calorie") as! String)
            lunchFoods.append(_meal)
            mealsInLocalStorage = true
          } else if meal.value(forKey: "meal") as! String == "D"{
            let _meal = Meal(name: meal.value(forKey: "name") as! String, meal: "D", date: meal.value(forKey: "date") as! String, calorie: meal.value(forKey: "calorie") as! String)
            dinnerFoods.append(_meal)
            mealsInLocalStorage = true
          } else{
            // not a valid food
          }
        }
      }
    }
    _tableView.reloadData()
    
    if mealsInLocalStorage{
      getFoodImages(date: date)
    }
    
    return mealsInLocalStorage
  }
  
  /**
   Saves a meal to local storage
   
   - parameter meal: Meal to save
   */
  func saveMealToLocalStorage(meal: Meal){
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let managedContext = appDelegate.managedObjectContext
    
    let entity =  NSEntityDescription.entity(forEntityName: "Meal",
                                             in:managedContext)
    let mealObject = NSManagedObject(entity: entity!,
                                     insertInto: managedContext)
    
    mealObject.setValue(meal.getName(), forKey: "name")
    mealObject.setValue(meal.getMeal(), forKey: "meal")
    mealObject.setValue(meal.getDate(), forKey: "date")
    mealObject.setValue(meal.getCalorie(), forKey: "calorie")
    
    do {
      try managedContext.save()
    } catch  { }
    
  }
}

// MARK: - UITableView Delegate, UITableView DataSource
extension CardTableViewController: UITableViewDelegate, UITableViewDataSource {
  /**
   Used by app to set titles for the headers of sections
   
   - parameter tableView: UITableView object
   - parameter section:   Section number
   
   - returns: Title of the section, or nil if section is not valid
   */
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return Constants.lunchHeaderText
    case 1:
      return Constants.dinnerHeaderText
    default:
      return nil
    }
  }

  /**
   Used by app to set the view for section headers
   
   - parameter tableView: UITableView object
   - parameter view:      View for section header
   - parameter section:   Section number
   */
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView //recast your view as a UITableViewHeaderFooterView
    header.contentView.backgroundColor = UIColor.primaryColor()
    header.textLabel!.textColor = UIColor.white
    header.textLabel?.font = UIFont.init(name: "Montserrat-Light", size: 17)
  }
  
  /**
   Manages the cells in the table view
   
   - parameter tableView: UITableView object
   - parameter indexPath: Index of the cell
   
   - returns: UITableViewCell for the given index
   */
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "card", for: indexPath as IndexPath) as! CardTableViewCell
    
    var meal:Meal
    
    if indexPath.section == 0 {
      meal = lunchFoods[indexPath.row]
    } else {
      meal = dinnerFoods[indexPath.row]
    }
    
    cell.nameField.text = meal.getName()
    cell.calorieField.text = meal.getCalorie()
    
    // remove all previous imageviews
    for v in cell._imageView.subviews{
      v.removeFromSuperview()
    }
    
    // add images
    let imageCount: Int = meal.getImageViews().count
    let perImageWidth: CGFloat = cell._imageView.frame.width / CGFloat(imageCount);
    var j: CGFloat = 0
    
    for imgView in meal.getImageViews() {
      imgView.frame = CGRect(x: j * perImageWidth, y: 0, width: perImageWidth, height: cell._imageView.frame.height)
      imgView.clipsToBounds = true
      imgView.contentMode = .scaleAspectFill
      cell._imageView.addSubview(imgView)
      cell.setNeedsLayout()
      j+=1
    }
    return cell
  }
  
  /**
   Used by app to determine the number of sections in the table view
   
   - parameter tableView: UITableView object
   
   - returns: Number of sections, 2 for this app. One for lunch foods, one for dinner foods.
   */
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  /**
   Used by app to determine the number of rows in each section of the table view
   
   - parameter tableView: UITableView object
   - parameter section:   Section number
   
   - returns: Number of rows
   */
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return lunchFoods.count
    }else{
      return dinnerFoods.count
    }
  }
}
