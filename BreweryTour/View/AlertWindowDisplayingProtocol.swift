//
//  AlertWindowDisplaying Protocol
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/1/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

protocol AlertWindowDisplaying {
    func displayAlertWindow(title: String, msg: String, actions: [UIAlertAction]?)
}


extension AlertWindowDisplaying where Self: UIViewController {

    // MARK: - Function
    
    // Specialized alert displays for UIViewControllers
    // This create a generic display with a dismiss embedded.
    // It can be expanded by adding more UIAlertActions.
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
