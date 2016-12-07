//
//  MyTabBarController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/6/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Navigation title"
        self.navigationItem.backBarButtonItem?.title = "Back button title"
        let dismissable = selectedViewController as! DismissableTutorial
        let helpButton = UIBarButtonItem(title: "Help?", style: .plain, target: dismissable, action: #selector(DismissableTutorial.enableTutorial))
        self.navigationItem.setRightBarButton(helpButton, animated: false)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Hey User selected another item on the tabbar")
    }

}
