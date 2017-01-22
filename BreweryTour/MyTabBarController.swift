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
 */

import UIKit

class MyTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Capture the selected ViewController so it can operate with the tutorial protocol.
        let dismissable = selectedViewController as! DismissableTutorial
        setHelpButton(tutorial: dismissable)
    }


    private func setHelpButton(tutorial dismissable: DismissableTutorial) {
        let helpButton = UIBarButtonItem(title: "Help?", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
        self.navigationItem.setRightBarButton(helpButton, animated: false)
    }

    
    internal func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let dismissable = viewController as! DismissableTutorial
        setHelpButton(tutorial: dismissable)
    }




}
