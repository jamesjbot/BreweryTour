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
    
    let paddingForPoint : CGFloat = 20
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var frc : NSFetchedResultsController<Brewery>
    
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
        frc.delegate = self
        // Do any additional setup after loading the view.
        performFetchOnResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetchOnResultsController()
        tableView.reloadData()
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
            displayAlertWindow(title: "Read Coredata", msg: "orry there was an error, \nplease try again.")
        }
        do {
            let results = try coreDataStack?.persistingContext.fetch(request)
        } catch {
            displayAlertWindow(title: "Read Coredata", msg: "Sorry there was an error, \nplease try again.")
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


