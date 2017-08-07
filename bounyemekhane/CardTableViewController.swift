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

class CardTableViewController: UIViewController {
  
  private var cachedMeals = [NSManagedObject]()
  
  @IBOutlet var _tableView: UITableView!
  @IBOutlet weak var dateField: UILabel!
  @IBOutlet weak var selectDateButton: UIButton!
  
  private var dateFormatter: DateFormatter = DateFormatter()
  private var date: String = ""
  private var pickerOpened:Bool = false
  private var picker : UIDatePicker = UIDatePicker()
  
  public var lunchFoods: [Meal] = []
  public var dinnerFoods: [Meal] = []
  public var imagePaths: NSDictionary = NSDictionary()
  
  let datePicker : UIDatePicker = UIDatePicker()
  let datePickerContainer = UIView()
  
  /**
   Opens up the datepicker screen
   
   - parameter sender: "Select the date" button in the navigation bar
   */
  @IBAction func selectDatePressed(sender: UIButton) -> Void {
    if(pickerOpened == false){
      pickerOpened = true
      _tableView.isScrollEnabled = false
      
      datePickerContainer.frame = CGRect(x: 0.0, y: sender.frame.height+15, width: self.view.frame.width, height: self.view.frame.height)
      datePickerContainer.backgroundColor = UIColor.white
      datePickerContainer.addSubview(datePicker)
      
      UIView.transition(with: self.view, duration: 0.5, options: UIViewAnimationOptions.transitionFlipFromRight, animations: {self.view.addSubview(self.datePickerContainer)}, completion: nil)
    }else{
      dismissPicker()
    }
  }
  
  /**
   Dismisses the datepicker screen and gets back into the food list screen
   */
  func dismissPicker() -> Void {
    UIView.transition(with: self.view, duration: 0.5, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: {self.datePickerContainer.removeFromSuperview()}, completion: nil)
    pickerOpened = false
    _tableView.isScrollEnabled = true
    dateField.text = date
    getFoodList(date: date)
  }
  
  /**
   Handles date field text & `date` property when user changes the date from datepicker
   
   - parameter sender: UIDatePicker in the "select a date" part of the program
   */
  func dateChanged(sender:UIDatePicker) -> Void{
    date = dateFormatter.string(from: sender.date)
    dateField.text = date
  }
  
  /**
   Initializes the date field text & `date` property
   */
  func initializeDate() -> Void{
    date = dateFormatter.string(from: Date())
    dateField.text = date
  }
  
  /**
   Parses JSON data
   
   - parameter inputData: NSData to be parsed into JSON (represented as NSDictionary)
   
   - returns: JSON data (represented as NSDictionary)
   */
  func parseJSON(inputData: NSData) -> NSDictionary{
    do{
      let boardsDictionary: NSDictionary = try JSONSerialization.jsonObject(with: inputData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
      return boardsDictionary
    }catch{ }
    return NSDictionary()
  }
  
  /**
   Adds an activity indicator to given view
   
   - parameter view: UIView object to add the indicator
   
   - returns: Indicator which is added to the view
   */
  func addActivityIndicator(view: UIView) -> UIActivityIndicatorView{
    let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50 ))
    loadingIndicator.center = view.center
    loadingIndicator.transform = CGAffineTransform(scaleX: 2, y: 2);
    loadingIndicator.center = self.view.center;
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
    view.addSubview(loadingIndicator)
    loadingIndicator.startAnimating();
    return loadingIndicator
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
   Pops up an alert with given title and string
   
   - parameter title: Title for the alert
   - parameter msg:   Message for the alert
   */
  func popUpAlert(title: String, msg: String){
    let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
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
    
    // add a loading indicator
    let loadingIndicator = addActivityIndicator(view: _tableView)
    
    Alamofire.request("\(AppConstants.apiURL)/cafeteria/menu/\(date)")
      .validate()
      .responseJSON { response in
        if response.result.isFailure {
          loadingIndicator.stopAnimating()
          loadingIndicator.removeFromSuperview()
          self.popUpAlert(title: "Hata", msg: "Sunucuyla bağlantı kurulamadı.")
        }else{
          let foodList: NSDictionary = response.result.value as! NSDictionary
          
          Alamofire.request("\(AppConstants.apiURL)/cafeteria/calories/\(date)")
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
                }else{
                  self.popUpAlert(title: "Üzgünüz", msg: "Seçilen gün için yemek servisi bulunmamaktadır.")
                }
                
                // remove the indicator
                loadingIndicator.stopAnimating()
                loadingIndicator.removeFromSuperview()
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
    Alamofire.request("\(AppConstants.apiURL)/cafeteria/images/\(date)")
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
  
  /**
   Executed after the view is loaded; it initializes the first view and sets some design options
   */
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dateFormatter.dateFormat = "YYYY/MM/dd"
    initializeDate()
    getFoodList(date: date)
    
    self._tableView.separatorColor = UIColor.clear // delete cell separators
    
    // Add white borders to datepicker button
    selectDateButton.layer.cornerRadius = 5
    selectDateButton.layer.borderWidth = 1
    selectDateButton.layer.borderColor = UIColor.white.cgColor
    selectDateButton.setTitleColor(AppConstants.mainBlueColor, for: .highlighted)
    
    // Set background&text colors of navbar
    let nav = self.navigationController?.navigationBar
    nav?.isTranslucent = false
    nav?.barTintColor = AppConstants.mainBlueColor // actual color is same as select date button highlight color
    nav?.tintColor = UIColor.white
    nav?.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
    nav?.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    nav?.shadowImage = UIColor.white.toImage()
    
    
    // get start of month
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: Date())
    let startOfMonth: Date = calendar.date(from: components)!
    // get end of month
    var comps2 = DateComponents()
    comps2.month = 1
    comps2.day = -1
    let endOfMonth: Date = calendar.date(byAdding: comps2, to: startOfMonth, wrappingComponents: true)!
    
    // instantiate datepicker frame
    datePicker.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300)
    
    datePicker.minimumDate = dateFormatter.date(from: "2016/04/01") // started storing data on April 1st
    datePicker.maximumDate = endOfMonth as Date
    datePicker.setDate(NSDate() as Date, animated: true)
    datePicker.datePickerMode = UIDatePickerMode.date
    datePicker.addTarget(self, action: #selector(CardTableViewController.dateChanged), for: UIControlEvents.valueChanged)
    
    // put a done button into the datepicker frame
    let doneButton = UIButton()
    doneButton.setTitle("Tamam", for: .normal)
    doneButton.setTitleColor(AppConstants.mainBlueColor, for: .normal)
    doneButton.addTarget(self, action: #selector(CardTableViewController.dismissPicker), for: .touchUpInside)
    doneButton.frame    = CGRect(x: 0, y: 300, width: self.view.frame.width, height: self.view.frame.height-408) // extra 108 pixels from navigation + status bar
    datePickerContainer.addSubview(doneButton)
    
    
  }
}

extension CardTableViewController: UITableViewDelegate, UITableViewDataSource {
  /**
   Used by app to set titles for the headers of sections
   
   - parameter tableView: UITableView object
   - parameter section:   Section number
   
   - returns: Title of the section, or nil if section is not valid
   */
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    if section == 0{
      return AppConstants.lunchHeaderText
    }else if section == 1{
      return AppConstants.dinnerHeaderText
    }
    
    return nil
  }

  /**
   Used by app to set the view for section headers
   
   - parameter tableView: UITableView object
   - parameter view:      View for section header
   - parameter section:   Section number
   */
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView //recast your view as a UITableViewHeaderFooterView
    header.contentView.backgroundColor = AppConstants.mainBlueColor
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
    
    if indexPath.section == 0{
      meal = lunchFoods[indexPath.row]
    }else{
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
    
    for imgView in meal.getImageViews(){
      imgView.frame = CGRect(x: j*perImageWidth, y: 0, width: perImageWidth, height: cell._imageView.frame.height)
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
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
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
