//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class CategoryViewController: UIViewController  {

    var filteredBeers = [style]()
    
    // MARK: Constants
    
    let cellIdentifier = "BeerTypeCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: IBOutlets
    
    @IBOutlet weak var newSearchBar: UISearchBar!
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    // MARK: IBAction clicked
    @IBAction func organicClicked(_ sender: AnyObject) {
        setTopTitleBarName()
    }
    
    // TODO Remove this and populate with another switchable property
    @IBAction func switchClicked(_ sender: AnyObject) {
        performSegue(withIdentifier:"Go", sender: sender)
    }

    
    private func setTopTitleBarName(){
        if organicSwitch.isOn {
            navigationController?.navigationBar.topItem?.title =  "Organic Brewery Tour"
        } else {
            navigationController?.navigationBar.topItem?.title =  "Brewery Tour"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let test = BreweryDBClient.sharedInstance()
        newSearchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        test.downloadBeerStyles(){
            (success) -> Void in
            if success {
                self.styleTable.reloadData()
            }
            
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fix the top title bar when we return
        setTopTitleBarName()
        guard styleTable.indexPathForSelectedRow == nil else {
            styleTable.deselectRow(at: styleTable.indexPathForSelectedRow!, animated: true)
            return
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            navigationController?.navigationBar.topItem?.title = "Back To Categories"
    }


}

extension CategoryViewController : UITableViewDataSource {
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredBeers = BreweryDBClient.sharedInstance().styleNames.filter({( s : style) -> Bool in
            let tempbool =  s.longName.lowercased().contains(searchText.lowercased())
            return tempbool
        })
        styleTable.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        if newSearchBar.text != "" {
            cell?.textLabel?.text = filteredBeers[indexPath.row].longName
        } else {
            cell?.textLabel?.text = BreweryDBClient.sharedInstance().styleNames[indexPath.row].longName
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if newSearchBar.text != ""{
            return filteredBeers.count
        }
        return BreweryDBClient.sharedInstance().styleNames.count
    }
}

extension CategoryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let style = BreweryDBClient.sharedInstance().styleNames[indexPath.row].id
        // TODO put activity indicator animating here
        BreweryDBClient.sharedInstance().downloadBreweries(styleID: style, isOrganic: organicSwitch.isOn){
            (success) -> Void in
            if success {
                self.performSegue(withIdentifier:"Go", sender: nil)
            }
        }
    }
}

extension CategoryViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_: UISearchBar, textDidChange: String){
        filterContentForSearchText(newSearchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Remove text so we stop searching
        // Put searchbar back into unselected state
        // Repopulate the table
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        styleTable.reloadData()
    }

}

extension CategoryViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    @objc(updateSearchResultsForSearchController:) func updateSearchResults(for searchController: UISearchController) {
        print("UISearchResultsUpdatingcallled")
        filterContentForSearchText(searchController.searchBar.text!)
        
    }
}

