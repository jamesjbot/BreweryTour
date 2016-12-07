//
//  MyTabBarController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/6/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO Do i want to populate these optional values
        self.navigationItem.title = "Navigation title"
        self.navigationItem.backBarButtonItem?.title = "Back button title"
        
        let dismissable = selectedViewController as! DismissableTutorial
        let helpButton = UIBarButtonItem(title: "Help?", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
        self.navigationItem.setRightBarButton(helpButton, animated: false)
    }

    internal func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let dismissable = viewController as! DismissableTutorial
        let helpButton = UIBarButtonItem(title: "Help?", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
        self.navigationItem.rightBarButtonItem = helpButton
    }
}
