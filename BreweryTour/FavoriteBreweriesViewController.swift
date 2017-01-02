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
 This is driven by an NSFetchedResultsController observing favoriteStatus's
 */

import UIKit
import CoreData
import CoreGraphics
import MapKit

class FavoriteBreweriesViewController: UIViewController {
    
    // MARK: Constants
    
    let paddingForPoint : CGFloat = 20
    //fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables

    // Currently this runs on main context readOnly
    fileprivate var frcForBrewery : NSFetchedResultsController<Brewery>!

    private var frc: NSFetchedResultsController<Brewery>? {
        get {
            print("accesing variable internal to the class")
            return NSFetchedResultsController()
        }
    }

    // MARK: IBOutlets

    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    
    @IBOutlet weak var tableView: UITableView!


    // MARK: IBActions
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.FavoriteBeersTutorial)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        assert(frc != nil)
        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        frcForBrewery.delegate = self
        // Do any additional setup after loading the view.
        performFetchOnResultsController()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
        tabBarController?.title = "Click For Directions"
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Animate tutorial
        tutorialText.text = "Select a brewery to show its location on the map"
        let tablePoint = CGPoint(x: tableView.frame.origin.x + paddingForPoint , y: tableView.frame.origin.y)
        pointer.center = tablePoint
        UIView.animateKeyframes(withDuration: 0.5,
                                delay: 0.0,
                                options: [ .autoreverse, .repeat ],
                                animations: { self.pointer.center.y += self.tableView.frame.height - (3*self.paddingForPoint) - (self.tabBarController?.tabBar.frame.height)! },
                                completion: nil)
        // Show tutorial
        if UserDefaults.standard.bool(forKey: g_constants.CategoryViewTutorial) {
            // Do nothing because the tutorial will show automatically.
        } else {
            tutorialView.isHidden = true
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
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frcForBrewery.object(at: indexPath as IndexPath) as Brewery? else {
            displayAlertWindow(title: "Error", msg: "Sorry there was an error formating page, \nplease try again.")
            return
        }
        // Populate cell from the NSManagedObject instance
        cell.textLabel?.text = selectedObject.name!
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = ""
        if let data : NSData = (selectedObject.image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
        }
    }
}


extension FavoriteBreweriesViewController: UpdateManagedObjectContext {


    internal func contextsRefreshAllObjects() {
        print("code from extension internal to the class")
        frcForBrewery.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try frcForBrewery.performFetch()
        } catch {

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
        return (frcForBrewery.fetchedObjects?.count)!
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
        // TODO This is in the main context now and I'm saving in the persistent context this could be wrong
        // Change this to be saving maincontext
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let object = self.frcForBrewery.object(at: indexPath)
            self.container?.performBackgroundTask({
                (context) -> Void in
                let brewery = context.object(with: object.objectID) as! Brewery
                brewery.favorite = false
                do {
                    try context.save()
                } catch {
                    self.displayAlertWindow(title: "Error Removing", msg: "Error removing item\nplease try again")
                }
                // TODO will you need to update the screen or will NSFetchedResultsControllerDelegate catch this
//                DispatchQueue.main.async {
//                    tableView.reloadData()
//                }
            })
        }
        deleteAction.backgroundColor = UIColor.green
        return [deleteAction]
    }
    
    
    // When we select a favorite brewery lets zoom to that brewery on the map
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("FavoriteBrewery \(#line) didSelectRowAt called. ")
        // Send the brewery to the mediator, then switch to the map tab
        Mediator.sharedInstance().selected(thisItem: frcForBrewery.object(at: indexPath)) {
            (success, msg) -> Void in
        }

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
}

extension FavoriteBreweriesViewController : DismissableTutorial {
    func enableTutorial() {
        tutorialView.isHidden = false
    }
}


