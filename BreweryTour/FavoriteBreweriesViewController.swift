//
//  FavoriteBreweriesViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/17/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This program show the favorited breweries.
    You can swipe left to remove the brewery from favorites.
    You can click on a brewery to show up on the map.
 **/

import UIKit
import CoreData
import CoreGraphics

class FavoriteBreweriesViewController: UIViewController {
    
    
    // MARK: Constants
    
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var frc : NSFetchedResultsController<Brewery>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("favorites tab enetered")
        frc.delegate = self
        // Do any additional setup after loading the view.
        performFetchOnResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("FavoriteBreweries view will appear called")
        super.viewWillAppear(animated)
        print("Fetching breweries")
        performFetchOnResultsController()
        tableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "favorite = YES")
        frc = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: (coreDataStack?.persistingContext)!,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        super.init(coder: aDecoder)
        performFetchOnResultsController()
    }
    
    
    fileprivate func performFetchOnResultsController(){
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "favorite = 1")
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: (coreDataStack?.persistingContext)!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        // Create a request for Brewery objects and fetch the request from Coredata
        do {
            try frc.performFetch()
            print("Number of favorite breweries returned \(frc.fetchedObjects?.count)")
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
        print("While direct fetch shows")
        do {
            let results = try coreDataStack?.persistingContext.fetch(request)
            print("Direct fetch results says \(results?.count)")
        } catch {
            fatalError()
        }
    }
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frc.object(at: indexPath as IndexPath) as Brewery? else { fatalError("Unexpected Object in FetchedResultsController") }
        // Populate cell from the NSManagedObject instance
        cell.textLabel?.text = selectedObject.name!
        // TODO please remove this is temporary so I can see the id
        cell.detailTextLabel?.text = "edited(\(selectedObject.id))"
        //cell.detailTextLabel?.text = selectedObject.brewer?.name
        if let data : NSData = (selectedObject.image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
            print("the output size will be \(cell.imageView?.frame.size)")
        }
    }
}

extension FavoriteBreweriesViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("=========>will change called")
        tableView.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("=========>didChange called")
        switch (type){
        case .insert:
            print("======> Insert called")
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: UITableViewRowAnimation.fade)
            break
        case .delete:
            print("=======> Delete called")
            tableView.deleteRows(at: [indexPath! as IndexPath], with: UITableViewRowAnimation.fade)
            break
        case .move:
            break
        case .update:
            print("=======> Update called")
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


extension FavoriteBreweriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called favoritesviewcontroller \(frc.fetchedObjects?.count)")
        assert(frc != nil)
        assert(frc.fetchedObjects != nil)
        performFetchOnResultsController()
        return (frc.fetchedObjects?.count)!
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
}

extension FavoriteBreweriesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            print("Action to do when you want to remove")
            let object = self.frc.object(at: indexPath) as Brewery
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
        // Send the brewery to the mediator, then switch to the map tab
        Mediator.sharedInstance().selected(thisItem: frc.object(at: indexPath))
        self.tabBarController?.selectedIndex = 0
    }
}


