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

 Optional* The user can turn on automatic go to the Map display in settings.
 This will then automatically bring the user to the map screen showing all
 breweries that were retrieved.
 
 Alternately the user can just select the name of a brewery in either 
 'Brewery with style' or 'All Breweries' this will bring the user to the map
 screen but only show them their selected brewery.

 The user can also search through available styles and available breweries
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
    
    private let styleList : StylesTableList! = StylesTableList()
    private let breweryList : BreweryTableList! = BreweryTableList()
    private let allBreweryList : AllBreweriesTableList = AllBreweriesTableList()

    // The communicator between objects.
    private let med : Mediator = Mediator.sharedInstance()

    // For cycling thru the states of the tutorial for the viewcontroller
    private enum CategoryTutorialStage {
        case SegementedControl
        case Table
        case BreweriesWithStyleTable
        case AllBreweries
        case InitialScreen
        case Map
        case RefreshDB
    }

    fileprivate enum SegmentedControllerMode: Int {
        case Style = 0
        case BreweriesWithStyle = 1
        case AllBreweries = 2
    }

    // Pointer animation duration
    private let pointerDuration : CGFloat = 1.0


    // MARK: Variables

    /*
     variables for saving the current indexpath
     when switching segmented controller
     */
    fileprivate var styleSelectionIndex: IndexPath?
    fileprivate var breweriesWithStyleSelectionIndex: IndexPath?
    fileprivate var allBreweriesSelectionIndex: IndexPath?
    
    private var tutorialModeOn : Bool = false {
        didSet {
            tutorialView.isHidden = !tutorialModeOn
        }
    }

    // Initialize the tutorial views initial screen
    private var tutorialState: CategoryTutorialStage = .InitialScreen

    // This is the active view model
    fileprivate var activeTableList : TableList!

    // Variable telling us if we should automatically go to map on completed request
    internal var automaticallySegueToMap: Bool = false


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
        // Set the tutorial off in permanent settings
        UserDefaults.standard.set(false, forKey: g_constants.CategoryViewTutorial)
        UserDefaults.standard.synchronize()
    }


    @IBAction func nextTutorialScreen(_ sender: AnyObject) {
        // Advance the tutorial state
        switch tutorialState {
        case .InitialScreen:
            tutorialState = .SegementedControl
        case .SegementedControl:
            tutorialState = .Table
        case .Table:
            tutorialState = .BreweriesWithStyleTable
        case .BreweriesWithStyleTable:
            tutorialState = .AllBreweries
        case .AllBreweries:
            tutorialState = .Map
        case .Map:
            tutorialState = .RefreshDB
        case .RefreshDB:
            tutorialState = .InitialScreen

        }

        // Show tutorial content
        switch tutorialState {
        case .InitialScreen:
            pointer.isHidden = true
            pointer.setNeedsDisplay()
            tutorialText.text = "Welcome to Brewery Tour. This app was designed to help you plan a trip to breweries that serve your favorite beer styles. Please step thru this tutorial with the next button. Dismiss it when you are done. To bring the tutorial back press Help?"

        case .SegementedControl:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Select 'Style' to show all breweries with that style on the map and in Breweries with Styles, or\nSelect 'Breweries with Style' to show breweries that make the selected style. Select 'All Breweries' to see all the breweries currently downoaded."
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding , y: segmentedControl.frame.midY)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - self.segmentedControlPaddding},
                                    completion: nil)
            break
        case .Table:
            tutorialText.text = "Select a style or a brewery from list, then go to the map to see its location"
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        case .BreweriesWithStyleTable:
            tutorialText.text = "When in the two breweries screen, you may notice not many breweries show up. There are many breweries available, we will load more breweries as you select more styles. Go back and choose a style of beer you would like to explore. Or go the 'All Breweries' screen and enter a name in the search bar to search for a brewery online."
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
                                    completion: nil)

        case .AllBreweries:
            tutorialText.text = "When 'All Breweries' is selected, you can search for a specific brewery from the internet by entering their name in the search bar"
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            let tablePoint = CGPoint(x: newSearchBar.frame.origin.x + paddingForPoint , y: newSearchBar.frame.midY)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.newSearchBar.frame.maxX - (2*self.paddingForPoint) },
                                    completion: nil)

        case .Map:
            tutorialText.text = "Click on 'Map' to proceed to the map, to view your last selection."
            pointer.isHidden = true
            pointer.setNeedsDisplay()
        
        
        case .RefreshDB:
            tutorialText.text = "If you would like to delete all beers, breweries, and styles information click the settings (gear) button. To go to the settings screen"
            pointer.isHidden = true
            pointer.setNeedsDisplay()
        }
    }

    
    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl, forEvent event: UIEvent) {

        //Capture the new screen mode
        let segmentedMode: SegmentedControllerMode = CategoryViewController.SegmentedControllerMode(rawValue: sender.selectedSegmentIndex)!

        switch segmentedMode {

        case .Style:
            activeTableList = styleList
            genericTable.reloadData()
            // Set the last selection
            genericTable.selectRow(at: styleSelectionIndex, animated: true, scrollPosition: .middle
            )
            newSearchBar.placeholder = "Select Style Below/Search here"

        case .BreweriesWithStyle:

            // Tell the the 'breweries with style' view model to prepare to
            // Show the selected style
            // If no style was selected then it will show the last style group 
            // That was selected.
            if styleSelectionIndex != nil {
                breweryList.prepareToShowTable()
            }
            activeTableList = breweryList
            genericTable.reloadData()
            // Set the last selection
            genericTable.selectRow(at: breweriesWithStyleSelectionIndex, animated: true, scrollPosition: .middle)
            newSearchBar.placeholder = "Select a brewery/Search here"


        case .AllBreweries:
            activeTableList = allBreweryList
            genericTable.reloadData()
            // Set the last selection
            genericTable.selectRow(at: allBreweriesSelectionIndex, animated: true, scrollPosition: .middle)
            newSearchBar.placeholder = "Select a brewery/Search here"
        }
    }
    
    
    @IBAction func mapButtonClicked(_ sender: AnyObject) {
        _ = sender.resignFirstResponder()// Sometimes the button clicks twice
        performSegue(withIdentifier:"Go", sender: sender)
    }
    
    
    // MARK: Functions
    
    // Receive notifcation when the TableList backing the current view has changed
    func sendNotify(from: AnyObject, withMsg msg: String) {
        // Only receive messages form the active tablelist
        if from === (activeTableList as AnyObject) {

        } else {
            return
        }
        print("Received message from \(from) \(msg)")
        print("Category \(#line) Do i still need this? ")
        guard (isViewLoaded && view.window != nil ),
            (from === (activeTableList as AnyObject)) else {
            // Do not process messages when CategoryViewController is not visisble unless you are the stylesTableList.
            return
        }

        print("Processing message from \(from) \(msg)")

        if msg.contains("All Pages Processed") {
            activityIndicator.stopAnimating()
        }

        // This will update the contents of the table if needed
        // TODO We're going to need to upgrade this function to accomodate all message.
        switch msg {

        case "stopIndicator":
            activityIndicator.stopAnimating()
            break

        case "reload data":
            // Only the active table should respond to a tablelist reload command
            if (activeTableList as AnyObject) === from {
                genericTable.reloadData()
                searchBar(newSearchBar, textDidChange: newSearchBar.text!)
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

        // Register for updates from the view models.
        styleList.registerObserver(view: self)
        breweryList.registerObserver(view: self)
        allBreweryList.registerObserver(view: self)
        
        // Make Breweries with style segmented control title fit
        (segmentedControl.subviews[1].subviews.first as! UILabel).adjustsFontSizeToFitWidth = true

        // set tutorial to the last screen, and advance into the first one
        // This is here because I want it to always shows the initial screen 
        // on a clean start. If user goes to another view and comes back they can 
        // resume their tutorial state
        tutorialState = .RefreshDB
        nextTutorialScreen(self)//Dummy to load data into the tutorial
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeTableList.filterContentForSearchText(searchText: newSearchBar.text!)

        // Change the Navigator name
        navigationController?.navigationBar.topItem?.title = "Select"

        // SegmentedControlClicked will reload the table.
        segmentedControlClicked(segmentedControl, forEvent: UIEvent())//Dummy event
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show tutorial
        if UserDefaults.standard.bool(forKey: g_constants.CategoryViewTutorial) {
            // Do nothing because the tutorial will show automatically.
        } else {
            tutorialView.isHidden = true
        }
    }
}


extension CategoryViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = genericTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        // Ask the viewmodel to populate our UITableViewCell
        //cell?.textLabel?.text = ""
        print("Want cell \(indexPath)")
        cell = activeTableList.cellForRowAt(indexPath: indexPath,
                                         cell: cell!,
                                         searchText: newSearchBar.text)
        print("Returned cell?")
        // Remove subtitle
        cell?.imageView?.contentMode = .scaleToFill
        cell?.detailTextLabel?.text = ""
        DispatchQueue.main.async {
            cell?.setNeedsDisplay()
        }
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)

    }
}


    // MARK: UITableViewDelegate

extension CategoryViewController : UITableViewDelegate {

    // Capture user selections, communicate with the mediator on what the
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Save the selection index
        switch SegmentedControllerMode(rawValue: segmentedControl.selectedSegmentIndex)! {
        case .Style:
            styleSelectionIndex = indexPath
            breweriesWithStyleSelectionIndex = nil
            allBreweriesSelectionIndex = nil
        case .BreweriesWithStyle:
            styleSelectionIndex = nil
            breweriesWithStyleSelectionIndex = indexPath
            allBreweriesSelectionIndex = nil
        case .AllBreweries:
            styleSelectionIndex = nil
            breweriesWithStyleSelectionIndex = nil
            allBreweriesSelectionIndex = indexPath
        }

        // Set the Textfield to the name of the selected item so the user
        // knows what they selected.
        selection.text = tableView.cellForRow(at: indexPath)?.textLabel?.text

        activityIndicator.startAnimating()


        let activeTableListSelectedCompletionHandler = {
            (success: Bool ,msg: String?) -> Void in
            // Every tablelist completion handler will come back here
            // TODO remember to tell every view model to
            // send back a completion handler.
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.setNeedsDisplay()
            }
            if success {
                self.displayAlertWindow(title: "Request sent", msg: "Your request was sent to the online service, your selection will load,\nin the background" )
                if Mediator.sharedInstance().isAutomaticallySegueing() {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "Go", sender: nil)
                    }
                }
            }
        }
        // Tell the view model something was selected.
        // The view model will go tell the mediator what it needs to download.
        _ = activeTableList.selected(elementAt: indexPath,
                                     searchText: newSearchBar.text!,
                                     completion: activeTableListSelectedCompletionHandler)
    }
}


    // MARK: - UISearchBar Delegate

extension CategoryViewController: UISearchBarDelegate {
    
    // Filter out selections not conforming to the searchbar text
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
    

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        /* 
         This method allows the user to put out a query to BreweryDB for
         breweries with the searchtext in their name

         Only allow the AllBreweries mode to searchonline for breweries
         this is because when in the styles mode the downloaded brewery 
         may not have that style and as such will not show up in the list
         making for a confusing experience.
         Same confusing experience goes for searching for styles.
         */

        guard segmentedControl.selectedSegmentIndex == SegmentedControllerMode.AllBreweries.rawValue else {
            // Block all other modes from search
            return
        }

        // Do nothing, because nothing entered in search bar, just return
        guard !(searchBar.text?.isEmpty)! else {
            return
        }

        // Definition of the function to be used in AlertWindow.
        func searchOnline(_ action: UIAlertAction){
            if activeTableList is OnlineSearchCapable {
                (activeTableList as! OnlineSearchCapable).searchForUserEntered(searchTerm: searchBar.text!) {
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
                activityIndicator.startAnimating()
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



