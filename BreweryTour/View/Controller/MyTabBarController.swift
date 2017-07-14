//
//  MyTabBarController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/6/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

/*
 This is the TabBarController that we will embed in the navigation controller.
 It allows us to setup a the help button in a single location.
 This is called by the interface
 */

import UIKit

class MyTabBarController: UITabBarController, UITabBarControllerDelegate {

    //var menuButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Capture the selected ViewController that is currently showing in the 
        // tab so it can operate with the tutorial protocol.
        let dismissable = selectedViewController as! DismissableTutorial
        setMenuAndHelpButton(tutorial: dismissable)
    }


    // Sets just the help button on the tabbarcontroller navigationbar
    private func setHelpButton(tutorial dismissable: DismissableTutorial) {
        DispatchQueue.main.async {
            self.navigationItem.setRightBarButtonItems([], animated: true)
            let helpButton = UIBarButtonItem(title: "Help", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
            self.navigationItem.setRightBarButton(helpButton, animated: false)
        }
    }


    // Sets the menu and help button on the tabbarcontroller navigationbar
    private func setMenuAndHelpButton(tutorial dismissable: DismissableTutorial ) {
        DispatchQueue.main.async {
            self.navigationItem.setRightBarButtonItems([], animated: true)
            let helpButton = UIBarButtonItem(title: "Help", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
            let menuButton = UIBarButtonItem(barButtonSystemItem: .add, target: self.selectedViewController, action: #selector(MapViewController.exposeMenu))
            self.navigationItem.setRightBarButtonItems([helpButton,menuButton], animated: true)
        }
    }

    // Is called when a tabbarController is selected
    internal func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let dismissable = viewController as! DismissableTutorial
        if dismissable is MapViewController {
            setMenuAndHelpButton(tutorial: dismissable)
            //menuButton?.isEnabled = true
        } else {
            setHelpButton(tutorial: dismissable)
            //menuButton?.isEnabled = false
        }
    }

}
