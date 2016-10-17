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
    

    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
            let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Beer")
            let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
            do {
                try coreDataStack?.mainStoreCoordinator.execute(batch, with: (coreDataStack?.favoritesContext)!)
                print("Batch Deleted completed")
            } catch {
                fatalError("batchdelete failed")
            }
    }
    
    // MARK: Constants
    
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var fetchedResultsController : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!

    
    
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
    

    private func perfromFetchOnResultsController(){
        fetchedResultsController.delegate = self
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
    }
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = fetchedResultsController.object(at: indexPath as IndexPath) as Beer? else { fatalError("Unexpected Object in FetchedResultsController") }
        // Populate cell from the NSManagedObject instance
        cell.textLabel?.text = selectedObject.beerName
        cell.detailTextLabel?.text = selectedObject.brewer?.name
        if let data : NSData = (selectedObject.image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
        }
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
            break
        case .update:
            configureCell(cell: tableView.cellForRow(at: indexPath!)!, indexPath: indexPath! as NSIndexPath)
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
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
}

extension FavoritesViewController : UITableViewDelegate {
    
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let object = (fetchedResultsController.fetchedObjects! as [Beer])[indexPath.row]
            coreDataStack?.favoritesContext.delete(object)
            do {
                try coreDataStack?.favoritesContext.save()
            } catch {
                fatalError("Error deleting row")
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Push beer information to Detail View Controller
        destinationViewcontroller.beer = fetchedResultsController.fetchedObjects?[indexPath.row]
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}

