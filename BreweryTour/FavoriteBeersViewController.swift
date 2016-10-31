//
//  FavoritesBeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/15/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class FavoriteBeersViewController: UIViewController {
    
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
    
    fileprivate var frc : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("favorites tab enetered")
        performFetchOnResultsController()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
        print("Favorites view controller sees this many favorite \(frc.fetchedObjects?.count)")
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
        frc.delegate = self
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
//        for (i,j) in (frc.fetchedObjects?.enumerated())! {
//            let path = IndexPath(row: i, section: 0)
//            let direct = frc.object(at: path) as Beer
//            print("direct: \(direct.beerName), set: \((j as Beer).beerName)")
//        }
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
    
//    @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let object = (frc.object(at: indexPath) as Beer)
//            coreDataStack?.favoritesContext.delete(object)
//            do {
//                try coreDataStack?.favoritesContext.save()
//            } catch {
//                fatalError("Error deleting row")
//            }
//        }
//    }
    
    
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
        print("OnScreen name:\(tableView.cellForRow(at: indexPath)?.textLabel?.text)")
        print("Background name: \(frc.object(at: indexPath).beerName)")
        destinationViewcontroller.beer = frc.object(at: indexPath)
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}


