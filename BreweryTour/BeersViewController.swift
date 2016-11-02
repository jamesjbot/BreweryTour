//
//  BeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BeersViewController: UIViewController, Observer {

    //TODO I haven't yet implemented the selectedBeerlist
    
    // MARK: Constants
    
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    fileprivate let selectedBeersTableList : SelectedBeersTableList = Mediator.sharedInstance().getSelectedBeersList()
    
    // MARK: Variables
    
    //fileprivate var frc : NSFetchedResultsController<Beer> = NSFetchedResultsController()
    
    internal var listOfBreweryIDToDisplay : [String]!

    // MARK: IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func segmentedClicked(_ sender: UISegmentedControl) {
        print("Segmented display clicked")
        selectedBeersTableList.toggleAllBeersMode()
    }
    // MARK: Functions
    
    func sendNotify(s: String) {
        "Beers View Controller was notified"
        tableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        print("Called reload data")
        //selectedBeersTableList.registerObserver(view: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        selectedBeersTableList.registerObserver(view: self)
        // Get information from the mediator as to what we are displaying
        // let managedObject = Mediator.sharedInstance().selectedItem()
//        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
//        request.sortDescriptors = []
//        
//        switch managedObject {
//        case is Brewery:
//            let targetID : String = (managedObject as! Brewery).id!
//            request.predicate = NSPredicate( format: "breweryID == %@", targetID)
//        case is Style:
//            let targetStyle : String = (managedObject as! Style).id!
//            request.predicate = NSPredicate( format: "styleID == %@", targetStyle )
//        default:
//            break
//        }
//        
//        frc = NSFetchedResultsController(fetchRequest: request,
//                                                              managedObjectContext: (coreDataStack?.backgroundContext)!,
//                                                              sectionNameKeyPath: nil,
//                                                              cacheName: nil)
//        // Create a request for Beer objects and fetch the request from Coredata
//        do {
//            try frc.performFetch()
//        } catch {
//            fatalError("There was a problem fetching from coredata")
//        }
        
//        let allbeers = frc.fetchedObjects! as [Beer]
//        for i in allbeers {
//            print("Brewery id \(i.breweryID)")
//        }
        //performFetchOnResultsController()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


//extension BeersViewController: NSFetchedResultsControllerDelegate {
//    
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//    }
//    
//    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//    }
//    
//    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//    }
//    
//
//}


extension BeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedBeersTableList.getNumberOfRowsInSection(searchText: searchBar.text)
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        var cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        cell = selectedBeersTableList.cellForRowAt(indexPath: indexPath, cell: cell, searchText: searchBar.text)
        return cell
    }

}

extension BeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let beer = selectedBeersTableList.selected(elementAt: indexPath, searchText: searchBar.text!) {
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
    
    
    // TODO calling database for brewery not currently downloaded.
    // I must get from here to to calling brwery db search for a brewery
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // Do nothing, because nothing entered in search bar
        guard !(searchBar.text?.isEmpty)! else {
            return
        }
        
        guard selectedBeersTableList.filterContentForSearchText(searchText: searchBar.text!).count == 0 else {
            return
        }
        
        // Prompt user should we go search online for the Brewery or style
        // Create action for prompt
//        func searchOnline(_ action: UIAlertAction) {
//            activityIndicator.startAnimating()
//            activeTableList.searchForUserEntered(searchTerm: searchBar.text!) {
//                (success, msg) -> Void in
//                self.activityIndicator.stopAnimating()
//                print("Returned from brewerydbclient")
//                if success {
//                    self.styleTable.reloadData()
//                } else {
//                    self.displayAlertWindow(title: "Search Failed", msg: msg!)
//                }
//            }
//        }
//        let action = UIAlertAction(title: "Search Online",
//                                   style: .default,
//                                   handler: searchOnline)
//        displayAlertWindow(title: "Search Online",
//                           msg: "Cannot find match on device,\nsearch online?",
//                           actions: [action])
    }
}
