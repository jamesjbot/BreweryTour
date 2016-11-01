//
//  ExtensionUIViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/1/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

extension UIViewController {


    // MARK: Specialized alert displays for UIViewControllers
    func displayAlertWindow(title: String, msg: String, actions: [UIAlertAction]? = nil){
        DispatchQueue.main.async {
            () -> Void in
            let alertWindow: UIAlertController = UIAlertController(title: title,
                                                                   message: msg,
                                                                   preferredStyle: UIAlertControllerStyle.alert)
            alertWindow.addAction(self.dismissAction())
            if let array = actions {
                for action in array {
                    alertWindow.addAction(action)
                }
            }
            self.present(alertWindow, animated: true, completion: nil)
        }
    }
    
    
    private func dismissAction()-> UIAlertAction {
        return UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
    }
    

}
