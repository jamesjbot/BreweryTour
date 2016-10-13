//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class CategoryViewController: UIViewController  {

    // MARK: Constants
    
    let cellIdentifier = "BeerTypeCell"
    
    // MARK: IBOutlets
    
    @IBOutlet weak var organicSwitch: UISwitch!
    @IBOutlet weak var styleTable: UITableView!
    
    // MARK: IBAction clicked
    
    @IBAction func switchClicked(_ sender: AnyObject) {
        // TODO Test code remove
        guard BreweryDBClient.sharedInstance().isReadyWithBreweryLocations() else {
            return
        }
        performSegue(withIdentifier:"Go", sender: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let test = BreweryDBClient.sharedInstance()
        // TODO Test code remove
        //test.downloadBreweries(styleID: "1", isOrganic: true)
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
        navigationController?.navigationBar.topItem?.title =  "Organic Brewery Tour"

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
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        cell?.textLabel?.text = BreweryDBClient.sharedInstance().styleNames[indexPath.row].id + ". " +
            BreweryDBClient.sharedInstance().styleNames[indexPath.row].longName
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BreweryDBClient.sharedInstance().styleNames.count
    }
}

extension CategoryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let style = BreweryDBClient.sharedInstance().styleNames[indexPath.row].id
        BreweryDBClient.sharedInstance().downloadBreweries(styleID: style, isOrganic: organicSwitch.isOn)
    }
}


