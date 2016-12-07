//
//  BeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** Shows all the beers or just the selected beers from styles or breweries.
 **/

import UIKit
import CoreData

class BeersViewController: UIViewController, Observer {
    
    // MARK: Constants
    
    enum SelectedBeersTutorialStage {
        case Table
        case SegementedControl
        case Organic
    }
    
    let segmentedControlPaddding : CGFloat = 8
    let paddingForPoint : CGFloat = 20

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    fileprivate let selectedBeersTableList : SelectedBeersTableList = Mediator.sharedInstance().getSelectedBeersList()
    
    // MARK: Variables
    
    internal var listOfBreweryIDToDisplay : [String]!
    private var tutorialState : SelectedBeersTutorialStage = .Table
    // MARK: IBOutlets
    
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialText: UITextView!
    
    @IBOutlet weak var nextLessonButton: UIButton!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // MARK: IBActions
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
    }
    
    @IBAction func segmentedClicked(_ sender: UISegmentedControl) {
        selectedBeersTableList.toggleAllBeersMode(control: sender)
    }
    
    @IBAction func organicSwitch(_ sender: UISwitch) {
        selectedBeersTableList.changeOrganicState(iOrganic: sender.isOn)
    }
    
    @IBAction func nextLesson(_ sender: UIButton) {
        // Advance the tutorial state
        switch tutorialState {
        case .Table:
            tutorialState = .SegementedControl
        case .SegementedControl:
            tutorialState = .Organic
        case .Organic:
            tutorialState = .Table
        }
        
        switch tutorialState {
        case .SegementedControl:
            // Set the initial point
            tutorialText.text = "Select Style to show all breweries with that style on map, or\nSelect Brewery to show that brewery on the map"
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding , y: segmentedControl.center.y + segmentedControlPaddding)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - self.segmentedControlPaddding},
                                    completion: nil)
            break
            
        case .Table:
            tutorialText.text = "Select a style or brewery from list to show on map"
            let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint , y: tableView.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.tableView.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        
        case .Organic:
            break
        }
    }

    
    // MARK: Functions
    
    func sendNotify(s: String) {
        tableView.reloadData()
        // Prompts the tableView to refilter search listings.
        searchBar(searchBar, textDidChange: searchBar.text!)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // When switching from another viewcontroller the background data might
        // have changed
        tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        selectedBeersTableList.registerObserver(view: self)
    }
    
}


extension BeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedBeersTableList.getNumberOfRowsInSection(searchText: searchBar.text)
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name, brewery and image if available
        var cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        cell.imageView?.image = nil
        cell = selectedBeersTableList.cellForRowAt(indexPath: indexPath, cell: cell, searchText: searchBar.text)
        // Set the uitableviewcell to update otherwise the cache version stays in place too long
        DispatchQueue.main.async {
            cell.setNeedsDisplay()
        }
        return cell
    }

}


extension BeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Open the beer detail view screen.
        // Temporarily put in false for organic type.
        // TODO pull the organic type from mediator.
        let beer = selectedBeersTableList.selected(elementAt: indexPath,
                                                   searchText: searchBar.text!) {
            (success,msg) -> Void in
        }
        // Create target viewcontroller
        let destinationViewcontroller = self.storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Push beer information to Detail View Controller
        destinationViewcontroller.beer = beer as! Beer
        
        // Segue to view controller
        self.navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }

}


extension BeersViewController : UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange: String){
        // User entered searchtext filter data
        selectedBeersTableList.filterContentForSearchText(searchText: textDidChange)
        tableView.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove searchbar text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    
    // Search for beer on line.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // Do nothing, because nothing was entered in search bar
        guard !(searchBar.text?.isEmpty)! else {
            return
        }
        
        // Prompt user to search online for beer
        // Create action for prompt
        func searchOnline(_ action: UIAlertAction) {
            activityIndicator.startAnimating()
            selectedBeersTableList.searchForUserEntered(searchTerm: searchBar.text!) {
                (success, msg) -> Void in
                self.activityIndicator.stopAnimating()
                if success {
                    self.tableView.reloadData()
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

extension BeersViewController : DismissableTutorial {
    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}
