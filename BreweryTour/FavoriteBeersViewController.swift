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
    
    let paddingForPoint : CGFloat = 20
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    // Currently this frc works on persistent
    fileprivate var frc : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    
    @IBOutlet weak var tableView: UITableView!

    // MARK: IBACtion
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.FavoriteBeersTutorial)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Function
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate( format: "favorite == YES")
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: (coreDataStack?.mainContext)!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        super.init(coder: aDecoder)
    }
    

    fileprivate func performFetchOnResultsController(){
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try frc.performFetch()
        } catch {
            displayAlertWindow(title: "Data access", msg: "Sorry there was an error accessing data try again.")
        }
    }
    
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let selectedObject = frc.object(at: indexPath as IndexPath) as Beer? else {
            displayAlertWindow(title: "Data Access", msg: "Sorry there was an error accessing data please try again")
            return
        }
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
            // TODO there is an error when in FavoriteBeers, select a beer and change tasting notes. It crashes.
            configureCell(cell: tableView.cellForRow(at: indexPath!)!, indexPath: indexPath! as NSIndexPath)
            break
        }
    }
    

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        performFetchOnResultsController()
        tableView.reloadData()
        tableView.endUpdates()
    }
}


extension FavoriteBeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (frc.fetchedObjects?.count) ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
}

extension FavoriteBeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Remove from Favorite") {
            (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let object = self.frc.object(at: indexPath) as Beer
            object.favorite = false
            do {
                try self.coreDataStack?.saveMainContext()
            } catch {
                self.displayAlertWindow(title: "Remove Error", msg: "Error removing item,\nplease try agains")            }
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
            displayAlertWindow(title: "Data access", msg: "Sorry there was a problem accessing data please try again")
        }
        destinationViewcontroller.beer = frc.object(at: indexPath)
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}

extension FavoriteBeersViewController : DismissableTutorial {
    func enableTutorial() {
        tutorialView.isHidden = false
    }
}


