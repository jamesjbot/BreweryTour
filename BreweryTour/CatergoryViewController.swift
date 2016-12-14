//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the main screen where users can choose to explore Beers by style.
    Once a style have been selected, the program will go get beers names and
    breweryies that posses that style of beer.
    The user will then be automatically brought to the map screen showing all
    breweries that were retried.
    The user can come back to the screen with the back button and select a
    brewery instead.
    If the user does this the user will be brought to the map showing only the 
    brewery they choose.
    The user can search through available styles and available breweries to see 
    if they have the one they are looking for.
    Finally we can select if we want to show only organic beers.
**/


import UIKit
import CoreData
import SwiftyWalkthrough

class CategoryViewController: UIViewController, NSFetchedResultsControllerDelegate ,
    Observer
    {
    // MARK: Constant
    let segmentedControlPaddding : CGFloat = 8
    let paddingForPoint : CGFloat = 20
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
        
    let cellIdentifier = "genericTypeCell"
    
    private let styleList : StylesTableList! = Mediator.sharedInstance().getStyleList()
    private let breweryList : BreweryTableList! = Mediator.sharedInstance().getBreweryList()
    
    private let med : Mediator = Mediator.sharedInstance()
    
    enum CategoryTutorialStage {
        case SegementedControl
        case Table
        case BreweryTable
        case InitialScreen
        case Map
        case RefreshDB
    }
    
    private let pointerDuration : CGFloat = 1.0
    
    // MARK: Variables
    
    private var tutorialModeOn : Bool = false {
        didSet {
            tutorialView.isHidden = !tutorialModeOn
        }
    }
    
    private var tutorialState : CategoryTutorialStage = .InitialScreen
    
    //TODO delete this when it's verified it's unneeded.
    //fileprivate var frc : NSFetchedResultsController<NSManagedObject>!
    
    fileprivate var activeTableList : TableList!
    
    private var explainedTable : Bool = false
    private var explainedSegmented : Bool = false
    
    
    @IBInspectable var fillColor: UIColor = UIColor.green
    
    // MARK: IBOutlets

    // Tutorial outlets
    @IBOutlet weak var mapButton: UIBarButtonItem!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var pointer: UIView!
    @IBOutlet weak var tutorialView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    //@IBOutlet weak var refreshDatabase: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    

    
    // MARK: IBActions
    @IBAction func tutorialButton(_ sender: UIBarButtonItem) {
        tutorialModeOn = true
    }

    @IBAction func dissMissTutorial(_ sender: UIButton) {
        tutorialModeOn = false
        UserDefaults.standard.set(false, forKey: g_constants.CategoryViewTutorial)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func nextCommandPressed(_ sender: AnyObject) {
        // Advance the tutorial state
        switch tutorialState {
        case .InitialScreen:
            tutorialState = .SegementedControl
        case .SegementedControl:
            tutorialState = .Table
        case .Table:
            tutorialState = .BreweryTable
        case .BreweryTable:
            tutorialState = .Map
        case .Map:
            tutorialState = .RefreshDB
        case .RefreshDB:
            tutorialState = .InitialScreen
        }
        
        switch tutorialState {
        case .InitialScreen:
            pointer.isHidden = true
            pointer.setNeedsDisplay()
            tutorialText.text = "Welcome to Brewery Tour. This app was designed to help you plan a trip to breweries that serve your favorite beer styles. Please step thru this tutorial with the next button. Dismiss it when you are done. To bring the tutorial back press Help?"
        case .SegementedControl:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Select Style to show all breweries with that style on map, or\nSelect Brewery to show that brewery on the map. When in Brewery mode if you don't see any breweries go back to styles and select a style. \nThe visible breweries are populated you select more styles."
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding , y: segmentedControl.center.y + segmentedControlPaddding)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - self.segmentedControlPaddding},
                                    completion: nil)
            break
        case .Table:
            tutorialText.text = "Select a style or a brewery from list, and you will be instantly taken to the map to show its locations"
            let tablePoint = CGPoint(x: styleTable.frame.origin.x + paddingForPoint , y: styleTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.styleTable.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        case .BreweryTable:
            tutorialText.text = "Don't see any breweries in Brewery Mode that is because there are alot of breweries. Go back and choose a style of beer you'd like to explore."
            let tablePoint = CGPoint(x: styleTable.frame.origin.x + paddingForPoint , y: styleTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.styleTable.frame.height - self.paddingForPoint },
                                    completion: nil)
        
        case .Map:
            tutorialText.text = "Click on Map to proceed to the map, to view your last selection."
            pointer.isHidden = true
            pointer.setNeedsDisplay()
        
        
        case .RefreshDB:
            tutorialText.text = "If you would like to delete all beers and brewery information click refresh button. To go to the deletion screen"
            pointer.isHidden = true
            pointer.setNeedsDisplay()
        }
    }

    
    @IBAction func organicClicked(_ sender: AnyObject) {
        //setTopTitleBarName()
        med.organic = organicSwitch.isOn
    }
    
    
    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        switch sender.selectedSegmentIndex{
        case 0:
            activeTableList = styleList
            styleTable.reloadData()
        case 1:
            activeTableList = breweryList
            styleTable.reloadData()
        default:
            break
        }
    }
    
    
    @IBAction func switchClicked(_ sender: AnyObject) {
        performSegue(withIdentifier:"Go", sender: sender)
    }
    
    
    // MARK: Functions
    
    // Receive notifcation when the TableList backing the current view has changed
    func sendNotify(s message : String) {
        // This will update the contents of the table if needed
        if message == "reload data" {
            styleTable.reloadData()
        }
        searchBar(newSearchBar, textDidChange: newSearchBar.text!)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Here we start initializer for style and brewery querying
        activeTableList = styleList
        styleList.mediator = med
        breweryList.mediator = med
        
        styleList.registerObserver(view: self)
        breweryList.registerObserver(view: self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Deselect whatever was selected on screen
        guard styleTable.indexPathForSelectedRow == nil else {
            styleTable.deselectRow(at: styleTable.indexPathForSelectedRow!, animated: true)
            return
        }
        // Always reload the table data. Incase new breweries were pulled in
        styleTable.reloadData()
        // Change the Navigator name
        navigationController?.navigationBar.topItem?.title = "Brewery Tour"
    }
    
    // Why is it taking me along time because the coordinates are changing when I apply them
    // to the tutorial text.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Always prime the tutorial
        nextCommandPressed(self)
        // Show tutorial
        if UserDefaults.standard.bool(forKey: g_constants.CategoryViewTutorial) {
            // Do nothing because the tutorial will show automatically.
        } else {
            tutorialView.isHidden = true
        }
    }
    
    
    // Changes the navigation bar to show user they can go back to categories screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.navigationBar.topItem?.title = "Style/Brewery"
    }
    
    func enumerateSubview(view: UIView, allowFull: UIView) {
        // Everything will be a parent view here
        print("Parent View: \(view)")
        let coordinates = view.convert(view.frame.origin, to: self.view)
        print("Coordinates: \(view.frame) Converted: \(view.convert(view.frame.origin, to: self.view))\n")
        if view == allowFull {
            print("found the view above\n")
print("\(view.convert(allowFull.frame.origin, to: self.view))")
            //CGRect(x: coordinates.x, y: coordinates.y, width: view.frame.width, height: view.frame.height)
        } else {
            for i in view.subviews {
                 enumerateSubview(view: i, allowFull: allowFull)
            }
        }
    }
    
}


extension CategoryViewController : UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        cell = activeTableList.cellForRowAt(indexPath: indexPath,
                                         cell: cell!,
                                         searchText: newSearchBar.text)
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)
        
    }
}


    // MARK: UITableViewDelegate

extension CategoryViewController : UITableViewDelegate {
    
    // Capture user selections, communicate with the mediator on what the
    // selection is and then proceed to the map on success
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("CategoryViewControler \(#line) tableView didSelectRowAt clled ")
        activityIndicator.startAnimating()
        activeTableList.selected(elementAt: indexPath,
                                 searchText: newSearchBar.text!){
        (sucesss,msg) -> Void in
            print("CategoryViewController didSelectRowAt completionHandler \(#line) \(msg!)")
            if msg == "All Pages Processed" {
                self.activityIndicator.stopAnimating()
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "Go", sender: nil)
                }
            }
        }
    }
}


    // MARK: - UISearchBar Delegate

extension CategoryViewController: UISearchBarDelegate {
    
    // A filter out selections not conforming to the searchbar text
    func searchBar(_: UISearchBar, textDidChange: String){
        // User entered searchtext filter data
        activeTableList.filterContentForSearchText(searchText: textDidChange)
        styleTable.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove searchbar text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        styleTable.reloadData()
    }
    
    
    // Querying BreweryDB for style/brewery not currently downloaded.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // Do nothing, because nothing entered in search bar
        guard !(searchBar.text?.isEmpty)! else {
            return
        }
        
        // Prompt user should we go search online for the Brewery or style
        // Create action for prompt
        func searchOnline(_ action: UIAlertAction){
            activityIndicator.startAnimating()
            activeTableList.searchForUserEntered(searchTerm: searchBar.text!) {
                (success, msg) -> Void in
                self.activityIndicator.stopAnimating()
                if success {
                    self.styleTable.reloadData()
                } else {
                    self.displayAlertWindow(title: "Search Failed", msg: msg!)
                }
            }
        }
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Cannot find match on device,\nsearch online?",
                           actions: [action])
    }
    
}



