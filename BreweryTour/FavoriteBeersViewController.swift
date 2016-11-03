//
//  FavoritesBeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/15/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This program show all the favorited beers in the database.
    Clicking on any beer will show you the detail.
    You can also swipe left to remove the beer from favorites
 **/


import UIKit
import CoreData

class FavoriteBeersViewController: UIViewController {
    
    // MARK: Constants
    
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var frc : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!

    
    // MARK: Function
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frc.delegate = self
        print("favorites tab enetered")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate( format: "favorite == YES")
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: (coreDataStack?.persistingContext)!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        super.init(coder: aDecoder)
    }
    

    fileprivate func performFetchOnResultsController(){
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try frc.performFetch()
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
    }
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frc.object(at: indexPath as IndexPath) as Beer? else { fatalError("Unexpected Object in FetchedResultsController") }
        // Populate cell from the NSManagedObject instance
        cell.textLabel?.text = selectedObject.beerName
        cell.detailTextLabel?.text = selectedObject.brewer?.name
        if let data : NSData = (selectedObject.image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
        }
    }
}


extension FavoriteBeersViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("will change called")
        tableView.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("didChange called")
        switch (type){
        case .insert:
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: UITableViewRowAnimation.fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath! as IndexPath], with: UITableViewRowAnimation.fade)
            break
        case .move:
            break
        case .update:
            configureCell(cell: tableView.cellForRow(at: indexPath!)!, indexPath: indexPath! as NSIndexPath)
            break
        }
    }
    

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        performFetchOnResultsController()
        tableView.reloadData()
        tableView.endUpdates()
        print("finished fetching and reloading table data.")
    }
}


extension FavoriteBeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called favoritesviewcontroller tableviewdatasource number of rows in section \(frc.fetchedObjects?.count)")
        return (frc.fetchedObjects?.count) ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        print("Called cell for row at index path \(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
}

extension FavoriteBeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            print("Action to do when you want to remove")
            let object = self.frc.object(at: indexPath) as Beer
            object.favorite = false
            do {
                try self.coreDataStack?.persistingContext.save()
            } catch {
                fatalError("Error deleting row")
            }
            tableView.reloadData()
        }
        deleteAction.backgroundColor = UIColor.green
        
        return [deleteAction]
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Push beer information to Detail View Controller
        if tableView.cellForRow(at: indexPath)?.textLabel?.text != frc.object(at: indexPath).beerName {
            fatalError()
        }
        destinationViewcontroller.beer = frc.object(at: indexPath)
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}

