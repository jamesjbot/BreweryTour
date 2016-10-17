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
    
    var filteredBeers = [Style]()
    
    // MARK: Constant
    fileprivate var fetchedResultsController : NSFetchedResultsController<Style>!
    
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    let breweryDB = BreweryDBClient.sharedInstance()
    
    let cellIdentifier = "BeerTypeCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: IBOutlets
    
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    // MARK: IBAction clicked
    @IBAction func organicClicked(_ sender: AnyObject) {
        setTopTitleBarName()
    }
    
    // TODO Remove this and populate with another switchable property
    @IBAction func switchClicked(_ sender: AnyObject) {
        performSegue(withIdentifier:"Go", sender: sender)
    }
    
    
    private func setTopTitleBarName(){
        if organicSwitch.isOn {
            navigationController?.navigationBar.topItem?.title =  "Organic Brewery Tour"
        } else {
            navigationController?.navigationBar.topItem?.title =  "Brewery Tour"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        
        // Search bar initialization
        newSearchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        request.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (coreDataStack?.persistingContext)!, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch failed critcally")
        }
        
        // If fetch did not return any items query the REST Api
        if fetchedResultsController.fetchedObjects?.count == 0 {
            breweryDB.downloadBeerStyles() {
                (success) -> Void in
                if success {
                    // TODO this might not be needed anymore
                    //self.styleTable.reloadData()
                }
            }
        }
    }
    
    
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fix the top title bar when we return
        setTopTitleBarName()
        guard styleTable.indexPathForSelectedRow == nil else {
            styleTable.deselectRow(at: styleTable.indexPathForSelectedRow!, animated: true)
            return
        }
        // Establish ourselves so we can receive updates
        fetchedResultsController.delegate = self
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.navigationBar.topItem?.title = "Back To Categories"
    }
 
    // TODO need to fill this all in
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("will change content")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("didchange object")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("didchange content")
        styleTable.reloadData()
    }
    
    
}

extension CategoryViewController : UITableViewDataSource {
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        
        filteredBeers = ((fetchedResultsController.fetchedObjects! as [Style]).filter {
            return ($0.displayName?.lowercased().contains(searchText.lowercased()))!
        } )
        styleTable.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        if newSearchBar.text != "" {
            cell?.textLabel?.text = filteredBeers[indexPath.row].displayName
        } else {
            cell?.textLabel?.text = ((fetchedResultsController.fetchedObjects?[indexPath.row])! as Style).displayName
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if newSearchBar.text != ""{
            return filteredBeers.count
        }
        return (fetchedResultsController.fetchedObjects?.count)!
    }
}

extension CategoryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let style = ((fetchedResultsController.fetchedObjects?[indexPath.row])! as Style).id
        // TODO put activity indicator animating here
        BreweryDBClient.sharedInstance().downloadBreweries(styleID: style!, isOrganic: organicSwitch.isOn){
            (success) -> Void in
            if success {
                self.performSegue(withIdentifier:"Go", sender: nil)
            }
        }
    }
}

extension CategoryViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_: UISearchBar, textDidChange: String){
        filterContentForSearchText(newSearchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        styleTable.reloadData()
    }
    
}

extension CategoryViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    @objc(updateSearchResultsForSearchController:) func updateSearchResults(for searchController: UISearchController) {
        print("UISearchResultsUpdatingcallled")
        filterContentForSearchText(searchController.searchBar.text!)
        
    }
}


