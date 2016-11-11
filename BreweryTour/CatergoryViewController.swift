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

class CategoryViewController: UIViewController, NSFetchedResultsControllerDelegate , Observer  {
    
    // TODO Is this testing code I can remove
    private func batchDelete() {
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
        do {
            try coreDataStack?.mainStoreCoordinator.execute(batch, with: (coreDataStack?.persistingContext)!)
        } catch {
            fatalError("batchdelete failed")
        }
        tableView(styleTable, numberOfRowsInSection: 0)
    }
    
    
    // MARK: Constant
    
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    let breweryDB = BreweryDBClient.sharedInstance()
    
    let cellIdentifier = "genericTypeCell"
    
    private let styleList : StylesTableList! = Mediator.sharedInstance().getStyleList()
    private let breweryList : BreweryTableList! = Mediator.sharedInstance().getBreweryList()
    
    private let med : Mediator = Mediator.sharedInstance()
    
    
    // MARK: Variables
    
    fileprivate var fetchedResultsController : NSFetchedResultsController<NSManagedObject>!
    
    fileprivate var activeTableList : TableList!
    
    
    // MARK: IBOutlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshDatabase: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    
    // MARK: IBActions
    @IBAction func refresh(_ sender: AnyObject) {
        coreDataStack?.deleteBeersAndBreweries()
    }

    
    @IBAction func organicClicked(_ sender: AnyObject) {
        setTopTitleBarName()
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
        // Fix the top title bar when we return
        setTopTitleBarName()
        
        // Deselect whatever was selected on screen
        guard styleTable.indexPathForSelectedRow == nil else {
            styleTable.deselectRow(at: styleTable.indexPathForSelectedRow!, animated: true)
            return
        }
    }
    
    
    private func setTopTitleBarName(){
        if organicSwitch.isOn {
            navigationController?.navigationBar.topItem?.title =  "Organic Brewery Tour"
        } else {
            navigationController?.navigationBar.topItem?.title =  "Brewery Tour"
        }
    }
    
    
    // Changes the navigation bar to show user they can go back to categories screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.navigationBar.topItem?.title = "Style/Brewery"
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
        activityIndicator.startAnimating()
        activeTableList.selected(elementAt: indexPath, searchText: newSearchBar.text!){
        (sucesss,msg) -> Void in
            print(msg)
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



