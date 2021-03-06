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
 First the stored TableLists are created selectedBeersTableList and allBeersTableList
 We set the default viewmodel
 We register with the view models as their observer

 */

import UIKit
import CoreData

class SelectedBeersViewController: UIViewController {

    // MARK: Constants

    fileprivate enum SegmentedControllerMode: Int {
        case SelectedBeers = 0
        case AllBeers = 1
    }

    private enum SelectedBeersTutorialStage {
        case Table
        case SegementedControl
        case SearchBar
    }

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    private let paddingForPoint : CGFloat = 20
    private let segmentedControlPaddding : CGFloat = 8

    // Pointer animation duration
    private let pointerDelay: CGFloat = 0.0
    private let textDelay: CGFloat = 0.5
    private let pointerDuration: CGFloat = 1.0

    fileprivate let allBeersViewModel: AllBeersViewModel = AllBeersViewModel()
    fileprivate let selectedBeersViewModel : SelectedBeersViewModel = SelectedBeersViewModel()


    // MARK: Variables

    fileprivate var activeViewModel: TableList!
    internal var listOfBreweryIDToDisplay : [String]!
    private var tutorialState : SelectedBeersTutorialStage = .Table

    // MARK: IBOutlets

    @IBOutlet weak var nextLessonButton: UIButton!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!


    // MARK: IBActions

    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.SelectedBeersShowTutorial)
        UserDefaults.standard.synchronize()
    }

    @IBAction func helpTapped(_ sender: Any) {
        tutorialView.isHidden = false
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
            UIView.transition(with: self.tutorialText,
                              duration: TimeInterval(self.textDelay),
                              options:  [.transitionFlipFromTop],
                              animations: {[unowned self] in self.tutorialText.text = "Choose 'Selected Beers' to show beers from style/brewery selection,\nChoose 'All Beers' to show all beers ever viewed on this device."},
                              completion: nil)
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding,
                                        y: segmentedControl.center.y)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - (2*self.segmentedControlPaddding)},
                                    completion: nil)
            break

        case .Table:
            UIView.transition(with: self.tutorialText,
                              duration: TimeInterval(self.textDelay),
                              options:  [.transitionFlipFromTop],
                              animations: {[unowned self] in self.tutorialText.text = "Select a beer to show its details."},
                              completion: nil)
            let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint ,
                                     y: tableView.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.tableView.frame.height - self.paddingForPoint },
                                    completion: nil)
            break


        case .SearchBar:
            UIView.transition(with: self.tutorialText,
                              duration: TimeInterval(self.textDelay),
                              options:  [.transitionFlipFromTop],
                              animations: {[unowned self] in self.tutorialText.text = "Enter the name of a beer, and we will search online for it."},
                              completion: nil)
            let tablePoint = CGPoint(x: searchBar.frame.origin.x + paddingForPoint , y: searchBar.frame.midY)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.searchBar.frame.maxX - (2*self.paddingForPoint) },
                                    completion: nil)
            break
            
        }

    }

    @IBAction func segmentedClicked(_ sender: UISegmentedControl) {

        let segmentedMode: SegmentedControllerMode = SelectedBeersViewController.SegmentedControllerMode(rawValue: sender.selectedSegmentIndex)!
        segmentedPressedChooseViewModel(withMode: segmentedMode)
    }

    // MARK: - Functions

    private func segmentedPressedChooseViewModel(withMode segmentedMode: SegmentedControllerMode) {
        switch segmentedMode {
            // Everytime we switch we have to refilter,
            // Here is the order of operations
            // If needed, filter beers
            // Set the backing model
            // Reload our local data.

        case .SelectedBeers: // Selected Beers mode

            if let text = searchBar?.text {
                selectedBeersViewModel.filterContentForSearchText(searchText: text)
            }
            activeViewModel = selectedBeersViewModel
            tableView.reloadData()
            DispatchQueue.main.async {
                self.searchBar.placeholder = "Search For Beer here"
            }

        case .AllBeers: // All Beers mode
            if let text = searchBar?.text {
                allBeersViewModel.filterContentForSearchText(searchText: text)
            }
            activeViewModel = allBeersViewModel
            tableView.reloadData()
            DispatchQueue.main.async {
                self.searchBar.placeholder = "Search For Beer here or online"
            }
        }
    }


    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the initial viewModel
        activeViewModel = selectedBeersViewModel

        //Register for updates from the view model
        selectedBeersViewModel.registerObserver(view: self)
        allBeersViewModel.registerObserver(view: self)

        // Register for searchBar updates
        searchBar.delegate = self

        // Register for stop activity indicator
        registerAsBusyObserverWithMediator()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // When switching from another viewcontroller the background data might
        // have changed
        tableView.reloadData()

        // Display only selected beers
        if activeViewModel is SelectedBeersViewModel {
            // Set selected subset as the first screen
            segmentedControl.selectedSegmentIndex = SegmentedControllerMode.SelectedBeers.rawValue
        } else {
            // Set All Beers as the first screen
            segmentedControl.selectedSegmentIndex = SegmentedControllerMode.AllBeers.rawValue
        }


        // Tell view model to load SelectedBeers
        segmentedClicked(segmentedControl)

        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            activityIndicator.startAnimating()
        }
        // Remove busy indicator.
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            [unowned self] timer in
            if Mediator.sharedInstance().isSystemBusy() == false {
                self.activityIndicator.stopAnimating()
                timer.invalidate()
            }
        }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Prime the tutorial state
        tutorialState = .SearchBar
        nextLesson(nextLessonButton)

        // Display the tutorial
        if UserDefaults.standard.bool(forKey: g_constants.MapViewShowTutorial) {
            // Do nothing
        } else {
            tutorialView.isHidden = true
        }
    }
}


// MARK: -  BusyObserver

extension SelectedBeersViewController: BusyObserver {

    func registerAsBusyObserverWithMediator() {
        Mediator.sharedInstance().registerForBusyIndicator(observer: self)
    }


    func startAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }


    func stopAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }

}


// MARK: - Observer

extension SelectedBeersViewController: Observer {

    // Method to receive notifications from outside this object.
    internal func sendNotify(from: AnyObject, withMsg msg: String) {
        // Prompts the tableView to refilter search listings.
        // TableView.reload will be handled by the searchBar function.
        // This means all notifications to SelectedBeersViewController will
        // reload the table.
        // Why do we invoke the search bar command? Because if there is
        // search text entered and we need to immediately filter the contents.
        searchBar(searchBar, textDidChange: searchBar.text!)
    }
}


// MARK: - UITableViewDataSource

extension SelectedBeersViewController: UITableViewDataSource {
    
    // Ask the model for a formatted UITableViewCell
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name, brewery and image if available
        // By sending the cell to the model to populate
        var cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        cell = activeViewModel.cellForRowAt(indexPath: indexPath, cell: cell, searchText: searchBar.text)
        // Set the uitableviewcell to update otherwise the cache version stays in place too long
        DispatchQueue.main.async {
            cell.setNeedsDisplay()
        }
        return cell
    }


    // Ask the model for the number of UITableViewCells
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeViewModel.getNumberOfRowsInSection(searchText: searchBar.text)
    }

}


// MARK: - UITableViewDelegate

extension SelectedBeersViewController : UITableViewDelegate {

    // Take the beer in the model and present it in the BeerDetailViewController
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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


// MARK: - UISearchBarDelegate

extension SelectedBeersViewController : UISearchBarDelegate, AlertWindowDisplaying {

    // Any text entered in the searchbar triggers this
    internal func searchBar(_ searchBar: UISearchBar, textDidChange: String){
        // User entered searchtext, now filter data
        if textDidChange.count == 0 {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
        activeViewModel.filterContentForSearchText(searchText: textDidChange) {
            (ok) -> Void in
            self.tableView.reloadData()
        }
    }


    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove searchbar text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }


    // Search for beer online at BreweryDB.
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        // Only Allow
        // AllBeerTableList to search online
        // This is because the preselection will not encompass the search results
        segmentedControl.selectedSegmentIndex = SegmentedControllerMode.AllBeers.rawValue
        segmentedClicked(segmentedControl)
        guard !(searchBar.text?.isEmpty)! else{
            // Escape beacuse nothing was entered in search bar
            return
        }

        // Function to attach to alert button
        func searchOnline(_ action: UIAlertAction) {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            activityIndicator.setNeedsDisplay()
            if activeViewModel is OnlineSearchCapable {
                (activeViewModel as! OnlineSearchCapable).searchForUserEntered(searchTerm: searchBar.text!) {
                    (success, msg) -> Void in
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                    if success {
                        self.tableView.reloadData()
                    } else {
                        self.displayAlertWindow(title: "Search Failed", msg: msg!)
                    }
                }
            }
        }
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Cannot find all matches on device,\ncan we search online?",
                           actions: [action])
    }
}


extension SelectedBeersViewController : DismissableTutorial {
    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}
