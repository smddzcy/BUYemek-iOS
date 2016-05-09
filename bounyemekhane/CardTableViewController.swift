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

extension UIColor{
    func toImage() -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        self.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class CardTableViewController: UITableViewController{
    
    private var cachedMeals = [NSManagedObject]()
    
    @IBOutlet var _tableView: UITableView!
    @IBOutlet weak var dateField: UILabel!
    @IBOutlet weak var selectDateButton: UIButton!
    
    private var dateFormatter: NSDateFormatter = NSDateFormatter()
    private var date: String = ""
    private var pickerOpened:Bool = false
    private var picker : UIDatePicker = UIDatePicker()
    
    private var lunchFoods: [Meal] = []
    private var dinnerFoods: [Meal] = []
    private var imagePaths: NSDictionary = NSDictionary()
    
    let datePicker : UIDatePicker = UIDatePicker()
    let datePickerContainer = UIView()
    
    /**
     Opens up the datepicker screen
     
     - parameter sender: "Select the date" button in the navigation bar
     */
    @IBAction func selectDatePressed(sender: UIButton) -> Void {
        if(pickerOpened == false){
            pickerOpened = true
            _tableView.scrollEnabled = false
            
            datePickerContainer.frame = CGRectMake(0.0, sender.frame.height+15, self.view.frame.width, self.view.frame.height)
            datePickerContainer.backgroundColor = UIColor.whiteColor()
            datePickerContainer.addSubview(datePicker)
            
            UIView.transitionWithView(self.view, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: {self.view.addSubview(self.datePickerContainer)}, completion: nil)
        }else{
            dismissPicker()
        }
    }
    
    /**
     Dismisses the datepicker screen and gets back into the food list screen
     */
    func dismissPicker() -> Void {
        UIView.transitionWithView(self.view, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {self.datePickerContainer.removeFromSuperview()}, completion: nil)
        pickerOpened = false
        _tableView.scrollEnabled = true
        dateField.text = date
        getFoodList(date)
    }
    
    /**
     Handles date field text & `date` property when user changes the date from datepicker
     
     - parameter sender: UIDatePicker in the "select a date" part of the program
     */
    func dateChanged(sender:UIDatePicker) -> Void{
        date = dateFormatter.stringFromDate(sender.date)
        dateField.text = date
    }
    
    /**
     Initializes the date field text & `date` property
     */
    func initializeDate() -> Void{
        date = dateFormatter.stringFromDate(NSDate())
        dateField.text = date
    }
    
    /**
     Parses JSON data
     
     - parameter inputData: NSData to be parsed into JSON (represented as NSDictionary)
     
     - returns: JSON data (represented as NSDictionary)
     */
    func parseJSON(inputData: NSData) -> NSDictionary{
        do{
            let boardsDictionary: NSDictionary = try NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
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
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0 , 50, 50))
        loadingIndicator.center = view.center
        loadingIndicator.transform = CGAffineTransformMakeScale(2, 2);
        loadingIndicator.center = self.view.center;
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
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
        meal.setImageView(UIImageView(image: UIImage(named: "noImage")), atIndex: 0)
        
        // if not nil, then its a multiple food line
        var imageURL = self.imagePaths.valueForKey(meal.getName()) as? NSArray
        if imageURL == nil && self.imagePaths.valueForKey(meal.getName()) != nil{ // single url
            imageURL = [String(self.imagePaths.valueForKey(meal.getName())!)]
        }
        
        // set images & download them asynchronously
        if (imageURL != nil){
            var j: Int = 0
            for url in imageURL! {
                let imagePart = UIImageView()
                imagePart.image = UIImage(named: "noImage")
                meal.setImageView(imagePart, atIndex: j)
                if url as? String != nil {
                    if let urlObj = NSURL(string: url as! String){
                        imagePart.kf_setImageWithURL(urlObj,
                                                     completionHandler: { (image, error, cacheType, imgURL) -> () in
                                                        // nothing on completion
                        })
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
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
     Gets food list from local storage or server (if local storage fails)
     
     - parameter date: Date to get the food list
     */
    func getFoodList(date: String){
        
        // no need to get the food list from server if it already exists on local storage
        if getMealsFromLocalStorage(date) {
            return
        }
        
        lunchFoods = []
        dinnerFoods = []
        self._tableView.reloadData()
        
        // add a loading indicator
        let loadingIndicator = addActivityIndicator(_tableView)
        
        Alamofire.request(.GET, "\(AppConstants.apiURL)/cafeteria/menu/\(date)")
            .validate()
            .responseJSON { response in
                if response.result.isFailure {
                    loadingIndicator.stopAnimating()
                    loadingIndicator.removeFromSuperview()
                    self.popUpAlert("Hata", msg: "Sunucuyla bağlantı kurulamadı.")
                }else{
                    let foodList: NSDictionary = response.result.value as! NSDictionary
                    
                    Alamofire.request(.GET, "\(AppConstants.apiURL)/cafeteria/calories/\(date)")
                        .validate()
                        .responseJSON {response2 in
                            
                            let calorieList: NSDictionary = response2.result.value as! NSDictionary
                            if let lunch = foodList.valueForKey("lunch") as? [String] {
                                let dinner = foodList.valueForKey("dinner") as? [String]
                                if lunch.count > 0 && dinner != nil && dinner!.count > 0{
                                    for i in lunch{
                                        let meal: Meal = Meal(name: i, meal: "L", date: date)
                                        if let calorie = calorieList.valueForKey(i) {
                                            meal.setCalorie("\(calorie)")
                                        }
                                        self.saveMealToLocalStorage(meal)
                                        self.lunchFoods.append(meal)
                                    }
                                    for i in dinner!{
                                        let meal: Meal = Meal(name: i, meal: "D", date: date)
                                        if let calorie = calorieList.valueForKey(i) {
                                            meal.setCalorie("\(calorie)")
                                        }
                                        self.saveMealToLocalStorage(meal)
                                        self.dinnerFoods.append(meal)
                                    }
                                }else{
                                    self.popUpAlert("Üzgünüz", msg: "Seçilen gün için yemek servisi bulunmamaktadır.")
                                }
                                
                                // remove the indicator
                                loadingIndicator.stopAnimating()
                                loadingIndicator.removeFromSuperview()
                                self._tableView.reloadData()
                                
                                self.getFoodImages(date)
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
        Alamofire.request(.GET, "\(AppConstants.apiURL)/cafeteria/images/\(date)")
            .validate()
            .responseJSON { response in
                if response.result.value != nil{
                    self.imagePaths = response.result.value as! NSDictionary
                }
                for meal in self.lunchFoods+self.dinnerFoods{
                    self.handleImageForFood(meal)
                }
                self._tableView.reloadData()
        }
    }
    
    /**
     Fetchs local storage and puts them into `cachedMeals`
     */
    func fetchLocalStorage(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Meal")
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
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
            if let mealDate = meal.valueForKey("date") as? String{
                if mealDate == date{
                    if meal.valueForKey("meal") as! String == "L" {
                        let _meal = Meal(name: meal.valueForKey("name") as! String, meal: "L", date: meal.valueForKey("date") as! String, calorie: meal.valueForKey("calorie") as! String)
                        lunchFoods.append(_meal)
                        mealsInLocalStorage = true
                    } else if meal.valueForKey("meal") as! String == "D"{
                        let _meal = Meal(name: meal.valueForKey("name") as! String, meal: "D", date: meal.valueForKey("date") as! String, calorie: meal.valueForKey("calorie") as! String)
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
            getFoodImages(date)
        }
        
        return mealsInLocalStorage
    }
    
    /**
     Saves a meal to local storage
     
     - parameter meal: Meal to save
     */
    func saveMealToLocalStorage(meal: Meal){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Meal",
                                                        inManagedObjectContext:managedContext)
        let mealObject = NSManagedObject(entity: entity!,
                                         insertIntoManagedObjectContext: managedContext)
        
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
        getFoodList(date)
        
        self._tableView.separatorColor = UIColor.clearColor() // delete cell separators
        
        // Add white borders to datepicker button
        selectDateButton.layer.cornerRadius = 5
        selectDateButton.layer.borderWidth = 1
        selectDateButton.layer.borderColor = UIColor.whiteColor().CGColor
        selectDateButton.setTitleColor(AppConstants.mainBlueColor, forState: .Highlighted)
        
        // Set background&text colors of navbar
        let nav = self.navigationController?.navigationBar
        nav?.translucent = false
        nav?.barTintColor = AppConstants.mainBlueColor // actual color is same as select date button highlight color
        nav?.tintColor = UIColor.whiteColor()
        nav?.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        nav?.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        nav?.shadowImage = UIColor.whiteColor().toImage()
        
        
        // get start of month
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month], fromDate: NSDate())
        let startOfMonth: NSDate = calendar.dateFromComponents(components)!
        // get end of month
        let comps2 = NSDateComponents()
        comps2.month = 1
        comps2.day = -1
        let endOfMonth: NSDate = calendar.dateByAddingComponents(comps2, toDate: startOfMonth, options: [])!
        
        // instantiate datepicker frame
        datePicker.frame = CGRectMake(0.0, 0, self.view.frame.width, 300)
        datePicker.minimumDate = dateFormatter.dateFromString("2016/04/01") // started storing data on April 1st
        datePicker.maximumDate = endOfMonth
        datePicker.setDate(NSDate(), animated: true)
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.addTarget(self, action: #selector(CardTableViewController.dateChanged), forControlEvents: UIControlEvents.ValueChanged)
        
        // put a done button into the datepicker frame
        let doneButton = UIButton()
        doneButton.setTitle("Tamam", forState: UIControlState.Normal)
        doneButton.setTitleColor(AppConstants.mainBlueColor, forState: UIControlState.Normal)
        doneButton.addTarget(self, action: #selector(CardTableViewController.dismissPicker), forControlEvents: UIControlEvents.TouchUpInside)
        doneButton.frame    = CGRectMake(0, 300, self.view.frame.width, self.view.frame.height-408) // extra 108 pixels from navigation + status bar
        datePickerContainer.addSubview(doneButton)
        
        
    }
    
    /**
     Used by app to determine the number of sections in the table view
     
     - parameter tableView: UITableView object
     
     - returns: Number of sections, 2 for this app. One for lunch foods, one for dinner foods.
     */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    /**
     Used by app to determine the number of rows in each section of the table view
     
     - parameter tableView: UITableView object
     - parameter section:   Section number
     
     - returns: Number of rows
     */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return lunchFoods.count
        }else{
            return dinnerFoods.count
        }
    }
    
    /**
     Manages the cells in the table view
     
     - parameter tableView: UITableView object
     - parameter indexPath: Index of the cell
     
     - returns: UITableViewCell for the given index
     */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("card", forIndexPath: indexPath) as! CardTableViewCell
        
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
            imgView.frame = CGRectMake(j*perImageWidth,0,perImageWidth, cell._imageView.frame.height)
            imgView.clipsToBounds = true
            imgView.contentMode = .ScaleAspectFill
            cell._imageView.addSubview(imgView)
            cell.setNeedsLayout()
            j+=1
        }
        
        return cell
    }
    
    
    /**
     Used by app to set titles for the headers of sections
     
     - parameter tableView: UITableView object
     - parameter section:   Section number
     
     - returns: Title of the section, or nil if section is not valid
     */
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
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
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView //recast your view as a UITableViewHeaderFooterView
        header.contentView.backgroundColor = AppConstants.mainBlueColor
        header.textLabel!.textColor = UIColor.whiteColor()
        header.textLabel?.font = UIFont.init(name: "Montserrat-Light", size: 17)
    }
    
    /**
     Gives a UIColor object colored with a given HEX code
     
     - parameter hex: HEX code
     
     - returns: UIColor object with given HEX code color
     */
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if cString.hasPrefix("#"){
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        if cString.characters.count != 6 {
            return UIColor.grayColor()
        }
        
        var rgbValue :UInt32 = 0
        
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1)
        )
    }
    
}