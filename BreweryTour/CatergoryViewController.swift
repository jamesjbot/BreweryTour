//
//  ViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class CategoryViewController: UIViewController {

    // MARK: IBAction clicked
    
    @IBAction func switchClicked(_ sender: AnyObject) {
        performSegue(withIdentifier:"Go", sender: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let test = BreweryDBClient.sharedInstance()
        test.downloadBeerTypes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }


}

