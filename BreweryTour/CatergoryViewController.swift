//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class CategoryViewController: UIViewController , UITableViewDelegate  {

    // MARK: Constants
    
    let cellIdentifier = "BeerTypeCell"
    
    // MARK: IBOutlets
    
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
        test.downloadBreweries(styleID: "1", isOrganic: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }


}

extension CategoryViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        cell?.textLabel?.text = BreweryDBClient.sharedInstance().styleNames[indexPath.row].longName
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BreweryDBClient.sharedInstance().styleNames.count
    }
}



