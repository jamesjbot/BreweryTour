//
//  BeersViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BeersViewController: UIViewController {

    // MARK: Constants
    
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Variables
    
    fileprivate var fetchedResultsController : NSFetchedResultsController<Beer>
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: Functions
    
    
    required init?(coder aDecoder: NSCoder) {
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: (coreDataStack?.mainContext)!,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        super.init(coder: aDecoder)
    }
    
    
    private func perfromFetchOnResultsController(){
        
        // Create a request for Beer objects and fetch the request from Coredata
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("There was a problem fetching from coredata")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        perfromFetchOnResultsController()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension BeersViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print()
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print()
    }
    

}


extension BeersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (fetchedResultsController.fetchedObjects?.count)!
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the tableview and populate with name
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeerCell", for: indexPath)
        cell.textLabel?.text = fetchedResultsController.fetchedObjects?[indexPath.row].beerName
        cell.detailTextLabel?.text = fetchedResultsController.fetchedObjects?[indexPath.row].brewer?.name
        return cell
    }

}

extension BeersViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}
