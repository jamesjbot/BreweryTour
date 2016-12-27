//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This is the main screen where users can choose to explore Breweries by the 
 beer styles they produce.

 Once a style has been selected, the program will go get beer names and
 breweries that possess that style of beer.

 The user can view the breweries with that style by clicking the segmented
 control 'Breweries with style'

 If the user presses 'Map' the app will bring them to the map screen of all the
 breweries that were displayed in the 'Breweries with style' screen.

 Optional* The user can turn on automatic map display in settings. 
 This will then automatically bring the user to the map screen showing all
 breweries that were retrieved.
 
 Alternately the user can just select the name of a brewery in either 
 'Brewery with style' or 'All Breweries' this will bring the user to the map
 screen but only show them their selected brewery.

 The user can also search through available styles and available breweries to see
 by name, just by entering the name in the searchbar.
 */


import UIKit
import CoreData
import SwiftyWalkthrough

class CategoryViewController: UIViewController,
    NSFetchedResultsControllerDelegate, Observer {

    // MARK: Constant
    private let segmentedControlPaddding : CGFloat = 8
    private let paddingForPoint : CGFloat = 20
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
        
    fileprivate let cellIdentifier = "genericTypeCell"
    
    private let styleList : StylesTableList! = Mediator.sharedInstance().getStyleList()
    private let breweryList : BreweryTableList! = Mediator.sharedInstance().getBreweryList()
    private let allBreweryList : AllBreweriesTableList = Mediator.sharedInstance().getAllBreweryList()
    
    private let med : Mediator = Mediator.sharedInstance()
    
    private enum CategoryTutorialStage {
        case SegementedControl
        case Table
        case BreweryTable
        case InitialScreen
        case Map
        case RefreshDB
    }

    fileprivate enum SegmentedControllerMode: Int {
        case Style = 0
        case BreweriesWithStyle = 1
        case AllBreweries = 2
    }
    
    private let pointerDuration : CGFloat = 1.0


    // MARK: Variables

    /*
     variables for saving the current indexpath
     when switching segmented controller
     */
    fileprivate var styleSelectionIndex: IndexPath?
    fileprivate var stylesBrewerySelectionIndex: IndexPath?
    fileprivate var brewerySelectionIndex: IndexPath?
    
    private var tutorialModeOn : Bool = false {
        didSet {
            tutorialView.isHidden = !tutorialModeOn
        }
    }
    
    private var tutorialState: CategoryTutorialStage = .InitialScreen
    
    fileprivate var activeTableList : TableList!

    private var styleSelection : IndexPath?
    private var styleAtBrewerySelection : IndexPath?
    private var allBreweriesSelection : IndexPath?


    // MARK: IBOutlets

    // Tutorial outlets
    @IBOutlet weak var mapButton: UIBarButtonItem!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var pointer: UIView!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var selection: UITextField!
    
    // Normal UI outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var genericTable: UITableView!
    

    // MARK: IBActions

    @IBAction func helpButton(_ sender: UIBarButtonItem) {
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
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        case .BreweryTable:
            tutorialText.text = "Don't see any breweries in Brewery Mode that is because there are alot of breweries. Go back and choose a style of beer you'd like to explore."
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
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

    
    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        let segmentedMode: SegmentedControllerMode = CategoryViewController.SegmentedControllerMode(rawValue: sender.selectedSegmentIndex)!
        switch segmentedMode {
        case .Style:
            activeTableList = styleList
            genericTable.reloadData()
            genericTable.selectRow(at: styleSelectionIndex, animated: true, scrollPosition: .middle
            )

        case .BreweriesWithStyle:
            //print("CategoryViewController \(#line) Switching to BreweryTableList and reloading ")
            // TODO
            // If the selected index on the styles table exists
            // tell brewerytablelist to select style
            if styleSelectionIndex != nil {
                breweryList.displayBreweriesWith(style: styleList.frc.object(at: styleSelectionIndex!)){
                    (success) -> Void in
                    genericTable.reloadData()
                    return
                }
                // Make this a completion handler and I can replace it later?
            }
            activeTableList = breweryList
            genericTable.reloadData()
            genericTable.selectRow(at: stylesBrewerySelectionIndex, animated: true, scrollPosition: .middle)

        case .AllBreweries:
            activeTableList = allBreweryList
            genericTable.reloadData()
            genericTable.selectRow(at: brewerySelectionIndex, animated: true, scrollPosition: .middle)
        }
    }
    
    
    @IBAction func mapButtonClicked(_ sender: AnyObject) {
        // Sometimes the simulator clicks the button twice
        _ = sender.resignFirstResponder()
        performSegue(withIdentifier:"Go", sender: sender)
    }
    
    
    // MARK: Functions
    
    // Receive notifcation when the TableList backing the current view has changed
    func sendNotify(from: AnyObject, withMsg msg: String) {
        // Do not process notify if the sender is not in visisble
        guard (isViewLoaded && view.window != nil ) else {
            return
        }
        // This will update the contents of the table if needed
        print("CategoryViewController \(#line) Received msg:\(msg)\n from:\(from) ")
        // TODO We're going to need to upgrade this function to accomodate all message.
        switch msg {
        case "reload data":
            // Only the active table should respond to a table reload command
            if (activeTableList as AnyObject) === from {
                print("CategoryViewController \(#line) Reloading data")
                genericTable.reloadData()
                searchBar(newSearchBar, textDidChange: newSearchBar.text!)
            } else {
                print("CategoryViewController \(#line) Ignoring reload as you are not active")
            }
            break
        case "We have styles":
            //searchBar(newSearchBar, textDidChange: newSearchBar.text!)
            break
        case "failure":
            displayAlertWindow(title: "Error", msg: "Sorry there was an error please try again")
        default:
            fatalError("uncaught message \(msg)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Here we start initializer for style and brewery querying
        activeTableList = styleList
        
        styleList.registerObserver(view: self)
        breweryList.registerObserver(view: self)
        allBreweryList.registerObserver(view: self)
        
        // Make second segmented control title fit
        (segmentedControl.subviews[1].subviews.first as! UILabel).adjustsFontSizeToFitWidth = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("CategoryViewController \(#line) Viewwillappearcalled ")

        activeTableList.filterContentForSearchText(searchText: newSearchBar.text!)
        // Change the Navigator name
        navigationController?.navigationBar.topItem?.title = "Select"
        // segmentedControlClicked will reload the table.
        segmentedControlClicked(segmentedControl, forEvent: UIEvent())
    }


    // Why is it taking me along time because the coordinates are changing when I apply them
    // to the tutorial text.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO why do i have to prime the tutorial it starts in the correct state
        // Because that is what i said in hte initialization step
        // Always prime the tutorial
        // This line maynot be needed anymore
        //nextCommandPressed(self)

        // Show tutorial
        if UserDefaults.standard.bool(forKey: g_constants.CategoryViewTutorial) {
            // Do nothing because the tutorial will show automatically.
        } else {
            tutorialView.isHidden = true
        }
    }


    // TODO this is already set in viewDidAppear don't think doing it again help
    // Changes the navigation bar to show user they can go back to categories screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //navigationController?.navigationBar.topItem?.title = "Select"
    }
}


extension CategoryViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("CategoryViewController \(#line) cellForRowAt called ")
        var cell = genericTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        // Ask the viewmodel for the cell.
        cell = activeTableList.cellForRowAt(indexPath: indexPath,
                                         cell: cell!,
                                         searchText: newSearchBar.text)
        //print("CategoryViewController \(#line) cellForRowAt exited ")
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("CategoryViewController \(#line) numberOfRowsInsection called ")
        return activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)

    }
}


    // MARK: UITableViewDelegate

extension CategoryViewController : UITableViewDelegate {
    
    // Capture user selections, communicate with the mediator on what the
    // selection is and then proceed to the map on success
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Save the selection as title of the ViewController
        switch SegmentedControllerMode(rawValue: segmentedControl.selectedSegmentIndex)! {
        case .Style:
            styleSelectionIndex = indexPath
            stylesBrewerySelectionIndex = nil
            brewerySelectionIndex = nil
        case .BreweriesWithStyle:
            styleSelectionIndex = nil
            stylesBrewerySelectionIndex = indexPath
            brewerySelectionIndex = nil
        case .AllBreweries:
            styleSelectionIndex = nil
            stylesBrewerySelectionIndex = nil
            brewerySelectionIndex = indexPath
        }

        // Set the Textfield to the name of the selected item so the user 
        // know what they selected.
        selection.text = tableView.cellForRow(at: indexPath)?.textLabel?.text

        activityIndicator.startAnimating()

        // Tell the view model something was selected.
        // The view model will go tell the mediator what it needs to download.
        activeTableList.selected(elementAt: indexPath,
                                 searchText: newSearchBar.text!){
                                    (sucesss,msg) -> Void in
                                    //print("CategoryViewController didSelectRowAt completionHandler \(#line) \(msg!)")
                                    self.activityIndicator.stopAnimating()
                                    if !sucesss {
                                        self.displayAlertWindow(title: "Error with Query", msg: msg!)
                                    }
                                    // TODO Temporarily relaxed requirements on callback.
                                    if (msg?.contains("All Pages Processed"))! {
                                        DispatchQueue.main.async {
                                            //TODO Disable automatic map seguea
                                            //self.performSegue(withIdentifier: "Go", sender: nil)
                                        }
                                    }
        }
    }
}


    // MARK: - UISearchBar Delegate

extension CategoryViewController: UISearchBarDelegate {
    
    // A filter out selections not conforming to the searchbar text
    func searchBar(_: UISearchBar, textDidChange: String){
        /* 
         User entered searchtext, filter data
         if there is text
         */
        if !textDidChange.isEmpty {
            activeTableList.filterContentForSearchText(searchText: textDidChange)
            genericTable.reloadData()
        }
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        /*
         Remove searchbar text so we stop searching
         Put searchbar back into unselected state
         Repopulate the table
         */
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        genericTable.reloadData()
    }
    
    
    /*
     This method allows the user to put out a query to BreweryDB for 
     breweries with the searchtext in their name
     */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        /* 
         Only allow the AllBreweries mode to searchonline for breweries
         this is because when in the styles mode the downloaded brewery 
         may not have that style and as such will not show up in the list
         making for a confusing experience.
         Same confusing experience goes for searching for styles. I've downloaded all the
         styles everytime we start up there are no more styles to search for.
         */
        guard segmentedControl.selectedSegmentIndex == SegmentedControllerMode.AllBreweries.rawValue else {
            return
        }

        // Do nothing, because nothing entered in search bar, just return
        guard !(searchBar.text?.isEmpty)! else {
            return
        }

        // Definition of the function to be used in AlertWindow.
        func searchOnline(_ action: UIAlertAction){
            activityIndicator.startAnimating()
            activeTableList.searchForUserEntered(searchTerm: searchBar.text!) {
                (success, msg) -> Void in
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                if success {
                    self.genericTable.reloadData()
                } else {
                    self.displayAlertWindow(title: "Search Failed", msg: msg!)
                }
            }
        }
        // Set the function to the action button
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Dismiss to review the search results\nor press Search Online\nto search for more.",
                           actions: [action])
    }
}



