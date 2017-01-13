//
//  SelectedBeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 Shows all the beers or just the selected beers from styles and/or breweries.
 
 Initialization process
 First Stored TableLists are created selectedBeersTableList and allBeersTableList
 
 */

import UIKit
import CoreData

class SelectedBeersViewController: UIViewController, Observer {
    
    // MARK: Constants
    private enum SelectedBeersTutorialStage {
        case Table
        case SegementedControl
        case SearchBar
    }

    fileprivate enum SegmentedControllerMode: Int {
        case SelectedBeers = 0
        case AllBeers = 1
    }

    private let segmentedControlPaddding : CGFloat = 8
    private let paddingForPoint : CGFloat = 20

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    fileprivate let selectedBeersTableList : SelectedBeersViewModel = SelectedBeersViewModel()
    fileprivate let allBeersTableList: AllBeersViewModel = AllBeersViewModel()


    // MARK: Variables
    
    internal var listOfBreweryIDToDisplay : [String]!
    private var tutorialState : SelectedBeersTutorialStage = .Table

    fileprivate var activeViewModel: TableList!


    // MARK: IBOutlets

    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var nextLessonButton: UIButton!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!


    // MARK: IBActions

    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.SelectedBeersTutorial)
        UserDefaults.standard.synchronize()
    }


    @IBAction func segmentedClicked(_ sender: UISegmentedControl) {
        print("selectedView \(#line) segementClicked ")
        // Currently if the segmented control 1 (all beers mode selected send true)
        // selectedBeersTableList.setAllBeersModeONThenperformFetch(sender.state.rawValue == 1 ? true :false)
        let segmentedMode: Int = sender.selectedSegmentIndex

        switch segmentedMode {

        case 0: // Selected Beers mode
            selectedBeersTableList.performFetchRequestFor(observerNeedsNotification: false)
            activeViewModel = selectedBeersTableList
            tableView.reloadData()
            //newSearchBar.placeholder = "Select Style Below/Search here"

        case 1: // All Beers mode
            allBeersTableList.performFetchRequestFor(observerNeedsNotification: false)
            // Tell the the 'breweries with style' view model to prepare to
            // Show the selected style
            // If no style was selected then it will show the last style group
            // That was selected.
//            if styleSelectionIndex != nil {
//                breweryList.prepareToShowTable()
//            }
            activeViewModel = allBeersTableList
            tableView.reloadData()
            // Set the last selection

        default: // Will never occur
            break
        }

    }


    @IBAction func nextLesson(_ sender: UIButton) {
        // Advance the tutorial state
        switch tutorialState {
        case .Table:
            tutorialState = .SegementedControl
        case .SegementedControl:
            tutorialState = .SearchBar
        case .SearchBar:
            tutorialState = .Table
        }
        
        switch tutorialState {
        case .SegementedControl:
            // Set the initial point
            tutorialText.text = "Choose 'Selected Beers' to show beers from style/brewery selection, Choose 'All Beers' to show all beers ever viewed on this device."
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding,
                                        y: segmentedControl.center.y)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - (2*self.segmentedControlPaddding)},
                                    completion: nil)
            break
            
        case .Table:
            tutorialText.text = "Select a beer to show its details."
            let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint ,
                                     y: tableView.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.tableView.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        
        
        case .SearchBar:
            tutorialText.text = "Enter the name of a beer, and we will search online for it."
            let tablePoint = CGPoint(x: searchBar.frame.origin.x + paddingForPoint , y: searchBar.frame.midY)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.searchBar.frame.maxX - (2*self.paddingForPoint) },
                                    completion: nil)
            break
        
        }
    }

    
    // MARK: - Functions

    override func viewDidLoad() {
        print("SelectedViewController \(#line) viewDidLoad ")
        super.viewDidLoad()

        // Set the initial viewModel
        activeViewModel = selectedBeersTableList

        //Register for updates from the view model
        selectedBeersTableList.registerObserver(view: self)
        allBeersTableList.registerObserver(view: self)

        // Register for searchBar updates
        searchBar.delegate = self

        // Initialize the active
        print("SelectedViewController \(#line) viewDidLoad exited ")
    }


    override func viewWillAppear(_ animated: Bool) {
        print("SelectedViewController \(#line) viewWillAppear ")
        super.viewWillAppear(animated)
        // When switching from another viewcontroller the background data might
        // have changed
        tableView.reloadData()

        // Set navigationbar title
        tabBarController?.title = "Click For Details"

        // Set Selected Beers as the first screen
        segmentedControl.selectedSegmentIndex = 0 // Selected Beers mode

        // Tell view model to load SelectedBeers
        segmentedClicked(segmentedControl)
    }


    override func viewDidAppear(_ animated: Bool) {
        print("SelectedViewController \(#line) viewDidAppear ")
        super.viewDidAppear(animated)
        // Prime the tutorial state
        tutorialState = .SearchBar
        nextLesson(nextLessonButton)
        // Display the tutorial

        if UserDefaults.standard.bool(forKey: g_constants.MapViewTutorial) {
            // Do nothing
        } else {
            tutorialView.isHidden = true
        }
    }


    // Method to receive notifications from outside this object.
    internal func sendNotify(from: AnyObject, withMsg msg: String) {
        fatalError()
        print("SelectedViewController \(#line) sendNotify ")
        // Prompts the tableView to refilter search listings.
        // TableReload will be handled by the searchBar function.
        // All notifications to SelectedBeersViewController will reload the table.
        searchBar(searchBar, textDidChange: searchBar.text!)
    }
}

// MARK: - SelectedBeersViewController: UITableViewDataSource

extension SelectedBeersViewController: UITableViewDataSource {
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("SelectedViewController \(#line) numberOfRowsInSection ")
        return activeViewModel.getNumberOfRowsInSection(searchText: searchBar.text)
    }
    
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("SelectedViewController \(#line) cellForRowAt ")
        // Get a cell from the tableview and populate with name, brewery and image if available
        var cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        //cell.imageView?.image = nil
        cell = activeViewModel.cellForRowAt(indexPath: indexPath, cell: cell, searchText: searchBar.text)
        // Set the uitableviewcell to update otherwise the cache version stays in place too long
        DispatchQueue.main.async {
            cell.setNeedsDisplay()
        }
        return cell
    }

}


extension SelectedBeersViewController : UITableViewDelegate {
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("SelectedViewController \(#line) didSelectRowAt ")
        // Open the beer detail view screen.
        let beer = activeViewModel.selected(elementAt: indexPath,
                                                   searchText: searchBar.text!) {
            (success,msg) -> Void in
            // We don't need to process anything in the compeltion hanlder
        }
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Inject beer information into Detail View Controller
        destinationViewcontroller.beer = beer as! Beer

        // Change the name of the back button on destinationViewController
        tabBarController?.title = "Back"

        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }

}


extension SelectedBeersViewController : UISearchBarDelegate {

    internal func searchBar(_: UISearchBar, textDidChange: String){
        print("SelectedViewController \(#line) textDidChange ")
        // User entered searchtext, now filter data
        activeViewModel.filterContentForSearchText(searchText: textDidChange)
        tableView.reloadData()
    }
    
    
    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("SelectedViewController \(#line) searchBarCancelButtonClicked ")
        // Remove searchbar text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    
    // Search for beer online at BreweryDB.
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("SelectedViewController \(#line) searchBarSearchButton ")
        searchBar.resignFirstResponder()

        // BLOCK ONLINE SEARCHES FROM SELECTEDBEERSTABLELIST, Allow AllBeerTableList to search online
        guard segmentedControl.selectedSegmentIndex == SegmentedControllerMode.AllBeers.rawValue else {
            return
        }

        guard !(searchBar.text?.isEmpty)! else {
            // Escape because nothing was entered in search bar
            return
        }


        // Function to attach to alert button
        func searchOnline(_ action: UIAlertAction) {
            print("SelectedViewController \(#line) searchOnline ")
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            activityIndicator.setNeedsDisplay()
            if activeViewModel is OnlineSearchCapable {
                (activeViewModel as! OnlineSearchCapable).searchForUserEntered(searchTerm: searchBar.text!) {
                    (success, msg) -> Void in
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    if success {
                        self.tableView.reloadData()
                    } else {
                        self.displayAlertWindow(title: "Search Failed", msg: "Please close the app\nandtry again.")
                    }
                }
            }
        }
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Cannot find match on device,\ncan we search online?",
                           actions: [action])
    }
}


extension SelectedBeersViewController : DismissableTutorial {
    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}
