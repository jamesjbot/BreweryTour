//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the main screen where users can choose to explore Beers by style.
    Once a style have been selected, the program will go get beers names and
    breweryies that posses that style of beer.
    The user will then be automatically brought to the map screen showing all
    breweries that were retried.
    The user can come back to the screen with the back button and select a
    brewery instead.
    If the user does this the user will be brought to the map showing only the 
    brewery they choose.
    The user can search through available styles and available breweries to see 
    if they have the one they are looking for.
    Finally we can select if we want to show only organic beers.
**/


import UIKit
import CoreData
import SwiftyWalkthrough

class CategoryViewController: UIViewController, NSFetchedResultsControllerDelegate ,
    Observer
    {
    
    // TODO Is this testing code I can remove
    private func batchDelete() {
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
        do {
            try coreDataStack?.mainStoreCoordinator.execute(batch, with: (coreDataStack?.persistingContext)!)
        } catch {
            fatalError("batchdelete failed")
        }
        tableView(styleTable, numberOfRowsInSection: 0)
    }
    
    
    // MARK: Constant
    let segmentedControlPaddding : CGFloat = 8
    let paddingForPoint : CGFloat = 20
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
        
    let cellIdentifier = "genericTypeCell"
    
    private let styleList : StylesTableList! = Mediator.sharedInstance().getStyleList()
    private let breweryList : BreweryTableList! = Mediator.sharedInstance().getBreweryList()
    
    private let med : Mediator = Mediator.sharedInstance()
    
    enum CategoryTutorialStage {
        case SegementedControl
        case Table
    }
    
    private let pointerDuration : CGFloat = 1.0
    
    // MARK: Variables
    
    private var tutorialModeOn : Bool = false {
        didSet {
            tutorialView.isHidden = !tutorialModeOn
        }
    }
    private var tutorialState : CategoryTutorialStage = .SegementedControl
    
    fileprivate var fetchedResultsController : NSFetchedResultsController<NSManagedObject>!
    
    fileprivate var activeTableList : TableList!
    
    private var explainedTable : Bool = false
    private var explainedSegmented : Bool = false
    
    
    @IBInspectable var fillColor: UIColor = UIColor.green
    
    // MARK: IBOutlets

    // Tutorial outlets
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var pointer: UIView!
    @IBOutlet weak var tutorialView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshDatabase: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    

    
    // MARK: IBActions
    @IBAction func tutorialButton(_ sender: UIBarButtonItem) {
        tutorialModeOn = true
    }

    @IBAction func dissMissTutorial(_ sender: UIButton) {
        tutorialModeOn = false
    }
    
    @IBAction func nextCommandPressed(_ sender: AnyObject) {
        // Advance the tutorial state
        switch tutorialState {
        case .SegementedControl:
            tutorialState = .Table
        case .Table:
            tutorialState = .SegementedControl
        }
        switch tutorialState {
        case .SegementedControl:
            // Set the initial point
            tutorialText.text = "Select Style to show all breweries with that style on map, or\nSelect Brewery to show that brewery on the map"
            let segmentPoint  = CGPoint(x: segmentedControl.frame.origin.x + segmentedControlPaddding , y: segmentedControl.center.y + segmentedControlPaddding)
            pointer.center = segmentPoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.segmentedControl.frame.width - self.segmentedControlPaddding},
                                    completion: nil)
            break
        case .Table:
            tutorialText.text = "Select a style or brewery from list to show on map"
            let tablePoint = CGPoint(x: styleTable.frame.origin.x + paddingForPoint , y: styleTable.frame.origin.y)
            pointer.center = tablePoint
            UIView.animateKeyframes(withDuration: 0.5,
                                    delay: 0.0,
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.y += self.styleTable.frame.height - self.paddingForPoint },
                                    completion: nil)
            break
        }
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        coreDataStack?.deleteBeersAndBreweries()
    }

    
    @IBAction func organicClicked(_ sender: AnyObject) {
        //setTopTitleBarName()
        med.organic = organicSwitch.isOn
    }
    
    
    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        switch sender.selectedSegmentIndex{
        case 0:
            activeTableList = styleList
            styleTable.reloadData()
        case 1:
            activeTableList = breweryList
            styleTable.reloadData()
        default:
            break
        }
    }
    
    
    @IBAction func switchClicked(_ sender: AnyObject) {
        performSegue(withIdentifier:"Go", sender: sender)
    }
    
    
    // MARK: Functions
    
    // Receive notifcation when the TableList backing the current view has changed
    func sendNotify(s message : String) {
        // This will update the contents of the table if needed
        if message == "reload data" {
            styleTable.reloadData()
        }
        searchBar(newSearchBar, textDidChange: newSearchBar.text!)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Here we start initializer for style and brewery querying
        activeTableList = styleList
        styleList.mediator = med
        breweryList.mediator = med
        
        styleList.registerObserver(view: self)
        breweryList.registerObserver(view: self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Deselect whatever was selected on screen
        guard styleTable.indexPathForSelectedRow == nil else {
            styleTable.deselectRow(at: styleTable.indexPathForSelectedRow!, animated: true)
            return
        }
//        let hole = UIView(frame: segmentedControl.frame)
//        hole.alpha = 0.0
//        tutorialView.addSubview(MakeTransparentHoleOnOverlayView(frame: segmentedControl.frame))
//        print("tutorialView CGRect \(tutorialView.frame)")
//        print("selfView CGRect \(self.view.frame)")
//        print("segmentedControl: \(segmentedControl.frame)")
//        tutorialView.setNeedsDisplay()
        // Testing walkthroug
        //enumerateSubview(view:  view, allowFull: segmentedControl)
        
        //makeAllViewsTransparent(inSet: view.subviews, exceptView: segmentedControl)
        // Tutorial text
    }
    
    // Why is it taking me along time because the coordinates are changing when I apply them
    // to the tutorial text.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Find the target end position and beginning position 
        // of the white pointer
        // Table tutorial
        let coordinates : CGPoint = view.convert(styleTable.frame.origin, to: self.view)
        //print("Coordinates are \(coordinates)")
        //coordinateValues.init(x: coordinates.x, y: coordinates.y)
        //let pointerCoord = CGPoint(x: coordinate.x, y: coordinates.y)
        pointer.frame.origin.x = CGFloat(floatLiteral: CGFloat.NativeType(coordinates.x))
        pointer.frame.origin.y = CGFloat(coordinates.y)
        // Animate the pointer
        nextCommandPressed(self)
//        UIView.animateKeyframes(withDuration: 20.0,
//                                delay: 0.0,
//                                options: [ .autoreverse, .repeat ],
//                                animations: { self.pointer.center.y += self.styleTable.frame.height - self.paddingForPoint },
//                                completion: nil)
    }
    
    
    // Changes the navigation bar to show user they can go back to categories screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.navigationBar.topItem?.title = "Style/Brewery"
    }
    
    func enumerateSubview(view: UIView, allowFull: UIView) {
        // Everything will be a parent view here
        print("Parent View: \(view)")
        let coordinates = view.convert(view.frame.origin, to: self.view)
        print("Coordinates: \(view.frame) Converted: \(view.convert(view.frame.origin, to: self.view))\n")
        if view == allowFull {
            print("found the view above\n")
print("\(view.convert(allowFull.frame.origin, to: self.view))")
            //CGRect(x: coordinates.x, y: coordinates.y, width: view.frame.width, height: view.frame.height)
        } else {
            for i in view.subviews {
                 enumerateSubview(view: i, allowFull: allowFull)
            }
        }
    }
    
//    func enumerateSubview(view: UIView, allowFull: UIView){
//        print("I am \(view)")
//        if view.subviews.isEmpty {
//            print("I have no subviews")
//            if view == allowFull || view is UIStackView {
//                view.alpha = 1.0
//            } else {
//                view.alpha = 0.1
//            }
//        }
//
//        for i in view.subviews {
//            enumerateSubview(view: i, allowFull: allowFull)
//        }
//    }
//    
//    
//    func makeAllViewsTransparent(inSet: [UIView], exceptView: UIView){
//        //print(inSet.subviews.contains(exceptView))
//        if inSet.count == 1 {
//            if view != exceptView {
//                print(view)
//                view.alpha = 0.25
//                DispatchQueue.main.async {
//                    self.view.setNeedsDisplay()
//                }
//            }
//        } else {
//            for i in inSet {
//                //makeAllViewsTransparent(inSet: i, exceptView: exceptView)
//            }
//        }
//
//    }
}


extension CategoryViewController : UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        cell = activeTableList.cellForRowAt(indexPath: indexPath,
                                         cell: cell!,
                                         searchText: newSearchBar.text)
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)
        
    }
}


    // MARK: UITableViewDelegate

extension CategoryViewController : UITableViewDelegate {
    
    // Capture user selections, communicate with the mediator on what the
    // selection is and then proceed to the map on success
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activityIndicator.startAnimating()
        activeTableList.selected(elementAt: indexPath,
                                 searchText: newSearchBar.text!){
        (sucesss,msg) -> Void in
            print(msg)
            if msg == "All Pages Processed" {
                self.activityIndicator.stopAnimating()
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "Go", sender: nil)
                }
            }
        }
    }
}


    // MARK: - UISearchBar Delegate

extension CategoryViewController: UISearchBarDelegate {
    
    // A filter out selections not conforming to the searchbar text
    func searchBar(_: UISearchBar, textDidChange: String){
        // User entered searchtext filter data
        activeTableList.filterContentForSearchText(searchText: textDidChange)
        styleTable.reloadData()
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove searchbar text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        styleTable.reloadData()
    }
    
    
    // Querying BreweryDB for style/brewery not currently downloaded.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        // Do nothing, because nothing entered in search bar
        guard !(searchBar.text?.isEmpty)! else {
            return
        }
        
        // Prompt user should we go search online for the Brewery or style
        // Create action for prompt
        func searchOnline(_ action: UIAlertAction){
            activityIndicator.startAnimating()
            activeTableList.searchForUserEntered(searchTerm: searchBar.text!) {
                (success, msg) -> Void in
                self.activityIndicator.stopAnimating()
                if success {
                    self.styleTable.reloadData()
                } else {
                    self.displayAlertWindow(title: "Search Failed", msg: msg!)
                }
            }
        }
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Cannot find match on device,\nsearch online?",
                           actions: [action])
    }
    
}



