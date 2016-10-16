//
//  FavoritesViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/15/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class FavoritesViewController: UIViewController {
    
    // MARK: Constants
    
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var fetchedResultsController : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    private func perfromFetchOnResultsController(){
        fetchedResultsController.delegate = self
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("favorites tab enetered")
        // Do any additional setup after loading the view.
        perfromFetchOnResultsController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: (coreDataStack?.favoritesContext)!,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        super.init(coder: aDecoder)
    }
    
}

extension FavoritesViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("will change called")
        tableView.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("didChange called")
        switch (type){
        case .insert:
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: UITableViewRowAnimation.fade)
        case .delete:
            tableView.deleteRows(at: [indexPath! as IndexPath], with: UITableViewRowAnimation.fade)
        case .move:
            // No action needed for this response
            break
        case .update:
            // No action 
            break
        }
    }
    

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
        print("finished")
    }
    
    
}


extension FavoritesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called favoritesviewcontroller \(fetchedResultsController.fetchedObjects?.count)")
        return (fetchedResultsController.fetchedObjects?.count)!
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        cell.textLabel?.text = fetchedResultsController.fetchedObjects?[indexPath.row].beerName
        cell.detailTextLabel?.text = fetchedResultsController.fetchedObjects?[indexPath.row].brewer?.name
        return cell
    }
    
}

extension FavoritesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Push beer information to Detail View Controller
        destinationViewcontroller.beer = fetchedResultsController.fetchedObjects?[indexPath.row]
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}


