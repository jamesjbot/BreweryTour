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
 
 Internals:
 This view is back by 3 view models
 When you select an item it passes this request to the view model to process,
 with a completion handler back to this view.
 The view model will intern notify the mediator what the selected item is.
 
 Take for example a style choice.
 Will call the TableViewDelegate didSelectRow (in the extension)
 Then a completion handler will be created and passed to the view model with
 the selected indexpath.
 The style view model will find the style then send it to the mediator with a
 The completion handler from the CategoryView.
 Then the mediator will pull in the selection and call the BreweryDBClient with the 
 selection and the completion handler.
 After the breweryDBClient submits the internet requests it will prompt the
 completion handler to stop animating. 
 The view model will patiently wait or new breweries to be stored in the style.
 The view model will use the NSFetchedResults controller delegate to pick up 
 These new breweries and display them.
 
 A map of the call looks like this.
 CategoryViewController -> ViewModel -> Mediator -> BreweryDB -> 
 CategoryViewController via completion to stop animating.
 Also the view model will associate itself with the style. So now its fetched
 results delegate is pulling in new breweries that are applied to the style.
 
 */


import UIKit
import CoreData

class CategoryViewController: UIViewController,
NSFetchedResultsControllerDelegate {

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    private let paddingForPoint : CGFloat = 20
    private let segmentedControlPaddding : CGFloat = 8

    internal let cellIdentifier = "genericTypeCell"

    private let allBreweryList : AllBreweriesTableList = AllBreweriesTableList()
    private let breweryList : BreweryTableList! = BreweryTableList()
    private let styleList : StylesTableList! = StylesTableList()

    // The communicator between objects.
    private let med : Mediator = Mediator.sharedInstance()

    // Pointer animation duration
    private let pointerDelay: CGFloat = 0.0
    private let pointerDuration: CGFloat = 0.5

    // For cycling thru the states of the tutorial for the viewcontroller
    private enum CategoryTutorialStage {
        case SegementedControl
        case Table
        case BreweriesWithStyleTable
        case AllBreweries
        case Map
        case RefreshDB
    }


    internal enum SegmentedControllerMode: Int {
        case Style = 0
        case BreweriesWithStyle = 1
        case AllBreweries = 2
    }


    // MARK: - Variables
    // This is the active view model
    internal var activeTableList : TableList!

    // Variable telling us if we should automatically go to map on completed request
    internal var automaticallySegueToMap: Bool {
        get {
            return Mediator.sharedInstance().isAutomaticallySegueing()
        }
    }

    internal var styleSelectionIndex: IndexPath?

    private var tutorialModeOn : Bool = false {
        didSet {
            tutorialView.isHidden = !tutorialModeOn
        }
    }

    // Initialize the tutorial views initial screen
    private var tutorialState: CategoryTutorialStage = .RefreshDB

    // MARK: - IBOutlets

    // Tutorial outlets
    @IBOutlet weak var mapButton: UIBarButtonItem!
    @IBOutlet weak var pointer: UIView!
    @IBOutlet weak var selection: UITextField!

    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!

    // Normal UI outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var genericTable: UITableView!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!


    // MARK: - IBActions

    @IBAction func dissMissTutorial(_ sender: UIButton) {
        tutorialModeOn = false
        // Set the tutorial off in permanent settings
        UserDefaults.standard.set(false, forKey: g_constants.CategoryViewTutorial)
        UserDefaults.standard.synchronize()
    }


    @IBAction func helpButton(_ sender: UIBarButtonItem) {
        tutorialModeOn = true
    }


    @IBAction func mapButtonClicked(_ sender: AnyObject) {
        _ = sender.resignFirstResponder() // Sometimes the button clicks twice
        performSegue(withIdentifier:"GoToMap", sender: sender)
    }


    @IBAction func nextTutorialScreen(_ sender: AnyObject) {
        // Advance the tutorial state
        switch tutorialState {
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
            tutorialState = .SegementedControl
        }

        // Show tutorial content
        switch tutorialState {

        case .SegementedControl:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Select 'Style' to show all breweries with that style on the map and in Breweries with Styles.\nSelect 'Breweries with Style' to show breweries that make the selected style.\nSelect 'All Breweries' to see all the breweries currently downoaded."
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding , y: segmentedControl.frame.midY)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - self.segmentedControlPaddding},
                                    completion: nil)
            break
        case .Table:
            tutorialText.text = "Select a style or a brewery from list, then go to the map to see its location"
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        case .BreweriesWithStyleTable:
            tutorialText.text = "When in the two breweries screen, you may notice not many breweries show up. There are many breweries available, we will load more breweries as you select more styles. Go back and choose a style of beer you would like to explore."
            let tablePoint = CGPoint(x: genericTable.frame.origin.x + paddingForPoint , y: genericTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.genericTable.frame.height - self.paddingForPoint },
                                    completion: nil)

        case .AllBreweries:
            tutorialText.text = "When 'All Breweries' is selected, you can search for a specific brewery from the internet by entering their name in the search bar"
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            let tablePoint = CGPoint(x: newSearchBar.frame.origin.x + paddingForPoint , y: newSearchBar.frame.midY)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.newSearchBar.frame.maxX - ( self.paddingForPoint ) },
                                    completion: nil)

        case .Map:
            tutorialText.text = "Click on 'Map' tab to proceed to the map, to view your last selection."
            pointer.isHidden = true
            pointer.setNeedsDisplay()


        case .RefreshDB:
            tutorialText.text = "If you would like to delete all beers, breweries, and styles information click the settings (gear) button. To go to the settings screen"
            pointer.isHidden = true
            pointer.setNeedsDisplay()
        }
    }


    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl, forEvent event: UIEvent) {

        // Capture the new screen mode
        let segmentedMode: SegmentedControllerMode = CategoryViewController.SegmentedControllerMode(rawValue: sender.selectedSegmentIndex)!

        switch segmentedMode {
            // Set the model
            // reload the data
            // Set the place holder text

        case .Style:
            filterContent()
            activeTableList = styleList
            genericTable.reloadData()
            newSearchBar.placeholder = "Select Style Below or Search here"


        case .BreweriesWithStyle:

            // Tell the the 'breweries with style' view model to prepare to
            // Show the selected style
            // If no style was selected then it will show the last style group
            // That was selected.
            if styleSelectionIndex != nil {
                breweryList.prepareToShowTable()
            }
            filterContent()
            activeTableList = breweryList
            genericTable.reloadData()
            newSearchBar.placeholder = "Select a brewery or Search here"


        case .AllBreweries:
            filterContent()
            activeTableList = allBreweryList
            genericTable.reloadData()
            newSearchBar.placeholder = "Select a brewery or Search online"
        }
    }


    // MARK: - Functions

    private func filterContent() {
        if let text = newSearchBar.text {
            allBreweryList.filterContentForSearchText(searchText: text)
        }
    }

    private func initializeTutorial() {
        // Set tutorial to the last screen, and advance into the first one
        // This is here because I want it to always shows the initial screen
        // on a clean start. If user goes to another view and comes back they can
        // resume their tutorial state
        tutorialState = .RefreshDB
        nextTutorialScreen(self)//Dummy to load data into the tutorial
    }


    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the initial viewModel
        activeTableList = styleList

        // Register for updates from the view models.
        styleList.registerObserver(view: self)
        breweryList.registerObserver(view: self)
        allBreweryList.registerObserver(view: self)

        // Make Breweries with style segmented control title fit
        (segmentedControl.subviews[1].subviews.first as! UILabel).adjustsFontSizeToFitWidth = true

        initializeTutorial()

        registerAsBusyObserverWithMediator()

    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeTableList.filterContentForSearchText(searchText: newSearchBar.text!){
            (success) -> Void in
            self.genericTable.reloadData()
        }
        
        // Change the Navigator name
        navigationController?.navigationBar.topItem?.title = "Select"

        // SegmentedControlClicked will reload the table.
        segmentedControlClicked(segmentedControl, forEvent: UIEvent())//Dummy event

        if Mediator.sharedInstance().isSystemBusy() {
            activityIndicator.startAnimating() // Start animating faster.
        }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show tutorial
        guard UserDefaults.standard.bool(forKey: g_constants.CategoryViewTutorial) else {
            tutorialView.isHidden = true
            return
        }
    }
}


