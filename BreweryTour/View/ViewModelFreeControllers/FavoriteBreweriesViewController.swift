//
//  FavoriteBreweriesViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/17/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
    This program shows the favorited breweries.
    You can swipe left to remove the brewery from favorites.
    You can click on a brewery to show directions to the brewery.
    After selecting a brewery you can go back to selected beers and see this
    brewery's beers.
    This is driven by an NSFetchedResultsController observing favoriteStatus's
 */

import UIKit
import CoreData
import CoreGraphics
import MapKit

class FavoriteBreweriesViewController: UIViewController, AlertWindowDisplaying {
    
    // MARK: - Constants
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let paddingForPoint : CGFloat = 20
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
    fileprivate let noPhotoImage = #imageLiteral(resourceName: "Nophoto.png")

    // MARK: - Variables

    fileprivate var frcForBrewery : NSFetchedResultsController<Brewery>!


    // MARK: - IBOutlets

    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!

    @IBOutlet weak var tableView: UITableView!


    // MARK: - IBActions
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.FavoriteBeersShowTutorial)
        UserDefaults.standard.synchronize()
    }

    @IBAction func helpTapped(_ sender: Any) {
        tutorialView.isHidden = false
    }
    
    // MARK: - Functions

    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frcForBrewery.object(at: indexPath as IndexPath) as Brewery? else {
            displayAlertWindow(title: "Error", msg: "Sorry there was an error formating page, \nplease try again.")
            return
        }
        // Populate cell from the NSManagedObject instance
        DispatchQueue.main.async {
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
            cell.imageView?.image = self.noPhotoImage
            cell.textLabel?.text = selectedObject.name!
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.detailTextLabel?.text = ""
            if let data : Data = selectedObject.image {
                let im = UIImage(data: data as Data)
                cell.imageView?.image = im
            }
        }

    }

    // Favorite Breweries now runs off of MainContext
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        performFetchOnResultsController()
    }


    fileprivate func performFetchOnResultsController(){
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "favorite = 1")
        frcForBrewery = NSFetchedResultsController(fetchRequest: request,
                                                   managedObjectContext: readOnlyContext!,
                                                   sectionNameKeyPath: nil,
                                                   cacheName: nil)
        // Create a request for Brewery objects and fetch the request from Coredata
        do {
            try frcForBrewery.performFetch()
        } catch {
            displayAlertWindow(title: "Read Coredata", msg: "Sorry there was an error, \nplease try again.")
        }
    }


    // MARK: - Life Cycle Management

    override func viewDidLoad() {
        super.viewDidLoad()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        // Do any additional setup after loading the view.
        performFetchOnResultsController()
        frcForBrewery.delegate = self

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Animate tutorial
        tutorialText.text = "Select a brewery to show directions to this location."
        let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint , y: tableView.frame.origin.y)
        pointer.center = tablePoint
        UIView.animateKeyframes(withDuration: AnimationConstant.pointerDuration,
                                delay: AnimationConstant.pointerDelay,
                                options: [ .autoreverse, .repeat ],
                                animations: { self.pointer.center.y += self.tableView.frame.height - (3*self.paddingForPoint) - (self.tabBarController?.tabBar.frame.height)! },
                                completion: nil)
        // Show tutorial
        if UserDefaults.standard.bool(forKey: g_constants.CategoryViewShowTutorial) {
            // Do nothing because the tutorial will show automatically.
        } else {
            tutorialView.isHidden = true
        }
    }

}
// MARK: - DismissableTutorial

extension FavoriteBreweriesViewController : DismissableTutorial {
    func enableTutorial() {
        tutorialView.isHidden = false
    }
}


// MARK: - NSFetchedResultsControllerDelegate

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


// MARK: - ReceiveBroadcastManagedObjectContextRefresh

extension FavoriteBreweriesViewController: ReceiveBroadcastManagedObjectContextRefresh {

    internal func contextsRefreshAllObjects() {
        frcForBrewery.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try frcForBrewery.performFetch()
        } catch {

        }
    }
}


// MARK: - UITableViewDataSource

extension FavoriteBreweriesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        performFetchOnResultsController()
        return (frcForBrewery.fetchedObjects?.count)!
    }
}


// MARK: - UITableViewDelegate

extension FavoriteBreweriesViewController : UITableViewDelegate {

    // When we select a favorite brewery lets zoom to that brewery on the map
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Send the brewery to the mediator so that selected beers will update with the selection
        (Mediator.sharedInstance() as MediatorBroadcastSetSelected).select(thisItem: frcForBrewery.object(at: indexPath),
                                                                           state: nil,
                                                                           completion: { (success, msg) -> Void in })
        // Switch to get directions to brewery
        if let lat = Double(frcForBrewery.object(at: indexPath).latitude!) ,
            let long = Double(frcForBrewery.object(at: indexPath).longitude!) {
            let location: MKPlacemark =  MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long ))
            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            let mapItem = MKMapItem(placemark: location)
            mapItem.name = frcForBrewery.object(at: indexPath).name
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }


    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let object = self.frcForBrewery.object(at: indexPath)
            self.container?.performBackgroundTask({
                (context) -> Void in
                context.automaticallyMergesChangesFromParent = true
                let brewery = context.object(with: object.objectID) as! Brewery
                brewery.favorite = false
                do {
                    try context.save()
                } catch {
                    self.displayAlertWindow(title: "Error Removing", msg: "Error removing item\nplease try again")
                }

                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            })
        }
        deleteAction.backgroundColor = UIColor.green
        return [deleteAction]
    }
}





