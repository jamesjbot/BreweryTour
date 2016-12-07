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
    
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: IBActions
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frc.delegate = self
        // Do any additional setup after loading the view.
        performFetchOnResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
    }
    
    
    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
        //print(self.navigationController?.viewControllers)
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
        // Needed as compiler complains that this isn't initialized
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
        } catch {
            displayAlertWindow(title: "Read Coredata", msg: "Error reading local device\nplease try again")
        }
        do {
            let results = try coreDataStack?.persistingContext.fetch(request)
        } catch {
            fatalError()
        }
    }
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frc.object(at: indexPath as IndexPath) as Brewery? else { fatalError("Unexpected Object in FetchedResultsController") }
        // Populate cell from the NSManagedObject instance
        cell.textLabel?.text = selectedObject.name!
        if let data : NSData = (selectedObject.image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
        }
    }
}

extension FavoriteBreweriesViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
        tableView.endUpdates()
        tableView.reloadData()
    }
}


extension FavoriteBreweriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            let object = self.frc.object(at: indexPath) as Brewery
            object.favorite = false
            do {
                try self.coreDataStack?.persistingContext.save()
            } catch {
                self.displayAlertWindow(title: "Error Removing", msg: "Error removing item\nplease try again")
            }
            tableView.reloadData()
        }
        deleteAction.backgroundColor = UIColor.green
        
        return [deleteAction]
    }
    
    
    // When we select a favorite brewery lets zoom to that brewery on the map
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Send the brewery to the mediator, then switch to the map tab
         // TODO I temporarily inserted a false this is wrong.
        Mediator.sharedInstance().selected(thisItem: frc.object(at: indexPath)) {
            (success, msg) -> Void in
        }
        self.tabBarController?.selectedIndex = 0
    }
}

extension FavoriteBreweriesViewController : DismissableTutorial {
    func enableTutorial() {
        tutorialView.isHidden = false
    }
}


