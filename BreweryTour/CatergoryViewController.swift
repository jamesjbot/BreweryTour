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
    
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    // MARK: IBAction clicked
    @IBAction func organicClicked(_ sender: AnyObject) {
        setTopTitleBarName()
    }
    
    @IBAction func switchClicked(_ sender: AnyObject) {
        // TODO Test code remove
        guard BreweryDBClient.sharedInstance().isReadyWithBreweryLocations() else {
            return
        }
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
        // TODO Test code remove
        //test.downloadBreweries(styleID: "1", isOrganic: true)
        //searchController.searchBar.sel
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        
        searchController.searchBar.showsScopeBar = false
        searchController.searchBar.placeholder = "Search or Select a Beer Style below"
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        styleTable.tableHeaderView = searchController.searchBar
        
        test.downloadBeerStyles(){
            (success) -> Void in
            if success {
                self.styleTable.reloadData()
            }
            
        }
    }
    
    // TODO Deselct entry when you get back to this window.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fix the top title bar when we return
        setTopTitleBarName()
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
        print("filtered content called")
        filteredBeers = BreweryDBClient.sharedInstance().styleNames.filter({( s : style) -> Bool in
            //let categoryMatch = (scope == "All") || (candy.category == scope)
            //categoryMatch &&
            return  s.longName.lowercased().contains(searchText.lowercased())
        })
        styleTable.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        if searchController.isActive && searchController.searchBar.text != "" {
            cell?.textLabel?.text = filteredBeers[indexPath.row].longName
        } else {
            cell?.textLabel?.text = BreweryDBClient.sharedInstance().styleNames[indexPath.row].longName
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != ""{
            return filteredBeers.count
        }
        return BreweryDBClient.sharedInstance().styleNames.count
    }
}

extension CategoryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let style = BreweryDBClient.sharedInstance().styleNames[indexPath.row].id
        BreweryDBClient.sharedInstance().downloadBreweries(styleID: style, isOrganic: organicSwitch.isOn)
    }
}

extension CategoryViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension CategoryViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    @objc(updateSearchResultsForSearchController:) func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!)
        
    }
}

