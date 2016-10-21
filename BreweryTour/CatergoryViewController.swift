//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewController: UIViewController, NSFetchedResultsControllerDelegate  {
    
    
    // TODO Is this testing code I can remove
    private func batchDelete() {
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
        do {
            try coreDataStack?.mainStoreCoordinator.execute(batch, with: (coreDataStack?.persistingContext)!)
            print("Batch Deleted completed")
        } catch {
            fatalError("batchdelete failed")
        }
    }
    
    
    // MARK: Constant
    fileprivate var fetchedResultsController : NSFetchedResultsController<NSManagedObject>!
    
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    let breweryDB = BreweryDBClient.sharedInstance()
    
    let cellIdentifier = "genericTypeCell"
    
    fileprivate var activeTableList : TableList!
    
    private let styleList : StylesTableList! = Mediator.sharedInstance().getStyleList()
    private let breweryList : BreweryTableList! = Mediator.sharedInstance().getBreweryList()
    
    private let med : Mediator = Mediator.sharedInstance()

    
    // MARK: IBOutlets
    @IBOutlet weak var refreshDatabase: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    // MARK: IBAction clicked
    @IBAction func refresh(_ sender: AnyObject) {
        coreDataStack?.deleteBeersAndBreweries()
    }

    
    @IBAction func organicClicked(_ sender: AnyObject) {
        setTopTitleBarName()
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Here we start initializer for style querying
        activeTableList = styleList
        styleList.mediator = med
        breweryList.mediator = med
        
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
        navigationController?.navigationBar.topItem?.title = "Back To Categories"
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
        var retVal : Int!
        retVal = activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)
        print("Number of rows in sections called returning \(retVal)")
        return retVal
    }
}


extension CategoryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activeTableList.selected(elementAt: indexPath){
        (sucesss) -> Void in
            self.performSegue(withIdentifier: "Go", sender: nil)
        }
//        switch segmentedControl.selectedSegmentIndex {
//        case 0: // Search breweries by style
//            break
//            // User has selected an onscreen style
//            // Now we go query breweryDB for all the breweries that have that style
//            // On a succesful query we Go to the map
//            //let style = styles[indexPath.row].id
//            // TODO put activity indicator animating here
////            BreweryDBClient.sharedInstance().downloadBreweriesBy(styleID: style!, isOrganic: organicSwitch.isOn){
////                (success) -> Void in
////                if success {
////                    self.performSegue(withIdentifier:"Go", sender: nil)
////                }
////            }
//        case 1: // Search breweries by name
//            print("case 1")
//        default:
//            print("default case")
//        }
    }
}


extension CategoryViewController: UISearchBarDelegate {
    
    
    // MARK: - UISearchBar Delegate
    
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
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchbar button clicked")
        searchBar.resignFirstResponder()
        // Good place to initiate asynchronous call to db
        // If search results are 0 go make a query to the database on the text.
        // If we're searching for breweries
        guard activeTableList.filterContentForSearchText(searchText: searchBar.text!).count == 0 else {
            return
        }
        guard segmentedControl.selectedSegmentIndex == 1 else {
            return
        }
//        let queue = DispatchQueue(label: "SearchForBrewery")
//        queue.async(qos: .utility){
//            BreweryDBClient.sharedInstance().downloadBreweryBy(name: searchBar.text!){
//                (success) -> Void in
//                if success {
//                    print("Returned from brewery client")
//                    // Notify the brewery list that we have a new brewery
//                    // This is done by NSFetchResultsController in the brewery list
//                    // Notify outselves to reload from the brewery
//                    self.styleTable.reloadData()
//                    //self.pullDataFromModelAndReloadTableView()
//                }
//            }
//        }
    }
}



