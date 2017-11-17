//
//  FavoritesBeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/15/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This program shows all the favorited beers in the database.
 Clicking on any beer will show you the detail.
 You can also swipe left to remove the beer from favorites
 */


import UIKit
import CoreData

class FavoriteBeersViewController: UIViewController, AlertWindowDisplaying {
    
    // MARK: - Constants

    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    private let paddingForPoint : CGFloat = 20
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
    fileprivate let reuseID = "FavoriteCell"
    fileprivate let noPhotoImage = #imageLiteral(resourceName: "Nophoto.png")

    // MARK: - Variables

    fileprivate var frc : NSFetchedResultsController<Beer>


    // MARK: - IBOutlets
    
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!

    @IBOutlet weak var tableView: UITableView!


    // MARK: - IBAction
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.FavoriteBeersShowTutorial)
        UserDefaults.standard.synchronize()
    }

    @IBAction func helpTapped(_ sender: Any) {
        tutorialView.isHidden = false
    }

    // MARK: - Functions

    fileprivate func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frc.object(at: indexPath as IndexPath) as Beer? else {
            displayAlertWindow(title: "Data Access", msg: "Sorry there was an error accessing data please try again")
            return
        }
        // Populate cell from the NSManagedObject instance
        DispatchQueue.main.async {
            cell.imageView?.image = self.noPhotoImage
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.textLabel?.text = selectedObject.beerName
            cell.detailTextLabel?.text = selectedObject.brewer?.name
            if let data : Data = selectedObject.image {
                let image = UIImage(data: data as Data)
                cell.imageView?.image = image
            }
        }
    }


    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate( format: "favorite == YES")
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        super.init(coder: aDecoder)
    }


    fileprivate func performFetchOnResultsController(){
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try frc.performFetch()
        } catch {
            displayAlertWindow(title: "Data access", msg: "Sorry there was an error accessing data please try again.")
        }
    }

    // MARK: - Life Cycle Management

    override func viewDidLoad() {
        super.viewDidLoad()
        // Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        frc.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Always prime the tutorial
        tutorialText.text = "Select a beer to show its details"
        let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint , y: tableView.frame.origin.y)
        pointer.center = tablePoint
        UIView.animateKeyframes(withDuration: AnimationConstant.pointerDuration,
                                delay: AnimationConstant.pointerDelay,
                                options: [ .autoreverse, .repeat ],
                                animations: { self.pointer.center.y += self.tableView.frame.height - (3*self.paddingForPoint) - (self.tabBarController?.tabBar.frame.height)! },
                                completion: nil)

        // Show tutorial
        guard UserDefaults.standard.bool(forKey: g_constants.CategoryViewShowTutorial) == true else {
            tutorialView.isHidden = true
            return
        }
    }
}


// MARK: - DismissableTutorial

extension FavoriteBeersViewController : DismissableTutorial {
    func enableTutorial() {
        tutorialView.isHidden = false
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension FavoriteBeersViewController: NSFetchedResultsControllerDelegate {
    
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


// MARK: - UITableViewDataSource

extension FavoriteBeersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (frc.fetchedObjects?.count) ?? 0
    }

}


// MARK: - UITableViewDelegate

extension FavoriteBeersViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController

        // Push beer information to Detail View Controller
        // If there is a data mismatch show error screen
        if tableView.cellForRow(at: indexPath)?.textLabel?.text != frc.object(at: indexPath).beerName {
            displayAlertWindow(title: "Data access", msg: "Sorry there was a problem accessing data please try again")
        }

        // Pass the beer to next view controller via injection
        destinationViewcontroller.beer = frc.object(at: indexPath)

        // Change the name of the back button
        tabBarController?.title = "Back"

        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }

    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.container?.performBackgroundTask({
                (context) -> Void in
                let object = self.frc.object(at: indexPath) as Beer
                object.favorite = false
                do {
                    try context.save()
                } catch {
                    self.displayAlertWindow(title: "Remove Error", msg: "Error removing item,\nplease try again")
                }
                tableView.reloadData()
            })
        }
        deleteAction.backgroundColor = UIColor.green
        return [deleteAction]
    }

}


// MARK: - UpdateManagedObjectContext

extension FavoriteBeersViewController: ReceiveBroadcastManagedObjectContextRefresh {
    func contextsRefreshAllObjects() {
        frc.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try frc.performFetch()
        } catch {
            NSLog("Error fetching")
        }
    }
}





