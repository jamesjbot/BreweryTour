//
//  BeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BeersViewController: UIViewController, Observer {

    
    // MARK: Constants
    
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    //internal let med : Mediator = Mediator.sharedInstance()

    // MARK: Variables
    
    fileprivate var frc : NSFetchedResultsController<Beer> = NSFetchedResultsController()
    
    internal var listOfBreweryIDToDisplay : [String]!
    
    
    private let selectedBeersTableList : SelectedBeersTableList = Mediator.sharedInstance().getSelectedBeersList()
    
    
    // MARK: IBOutlets
    

    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: Functions
    
    func sendNotify(s: String) {
        tableView.reloadData()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func performFetchOnResultsController(){
        
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try frc.performFetch()
            print("\(#function) returned \(frc.fetchedObjects?.count) objects")
            
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedBeersTableList.registerObserver(view: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get information from the mediator as what we are displaying
        let managedObject = Mediator.sharedInstance().selectedItem()
        
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        
        switch managedObject {
        case is Brewery:
            let targetID : String = (managedObject as! Brewery).id!
            request.predicate = NSPredicate( format: "breweryID == %@", targetID)
        case is Style:
            let targetStyle : String = (managedObject as! Style).id!
            request.predicate = NSPredicate( format: "styleID == %@", targetStyle )
        default:
            break
        }
        
        frc = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: (coreDataStack?.backgroundContext)!,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try frc.performFetch()
            print("\(#function) returned \(frc.fetchedObjects?.count) objects")
            
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
        
        let allbeers = frc.fetchedObjects! as [Beer]
        for i in allbeers {
            print("Brewery id \(i.breweryID)")
        }
        //performFetchOnResultsController()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}


extension BeersViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    

}


extension BeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (frc.fetchedObjects?.count)!
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        cell.textLabel?.text = frc.fetchedObjects?[indexPath.row].beerName
        cell.detailTextLabel?.text = frc.fetchedObjects?[indexPath.row].brewer?.name
        if let data : NSData = (frc.fetchedObjects?[indexPath.row].image) {
            let im = UIImage(data: data as Data)
            cell.imageView?.image = im
        }

        return cell
    }

}

extension BeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create target viewcontroller
        let destinationViewcontroller = storyboard?.instantiateViewController(withIdentifier: "BeerDetailViewController") as! BeerDetailViewController
        
        // Push beer information to Detail View Controller
        destinationViewcontroller.beer = frc.fetchedObjects?[indexPath.row]
        
        // Segue to view controller
        navigationController?.pushViewController(destinationViewcontroller, animated: true)
    }
}
