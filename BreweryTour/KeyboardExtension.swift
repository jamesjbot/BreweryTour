//
//  KeyboardExtension.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/22/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import UIKit

extension BeerDetailViewController {
    /*
     
     Keyboard elevating functions, will move the view up the same distance as 
     the height of the keyboard so that the keyboard doesn't block the bottom
     most views.
     
     */
    // MARK: - Keyboard elevating functions
    
    // Generates a keyboard height for the bottom textfield, generates 0 for top textfield
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let keyboardSize = (notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue// of CGRect
        return keyboardSize.cgRectValue.height
    }


    // Moves the view up prior to presenting keyboard
    func keyboardWillShow(_ notification: Notification){
        
        view.autoresizesSubviews = false
        // Get height of keyboard and save it globally
        let myKeyboardHeight = getKeyboardHeight(notification)
        // Move the whole UIView up by the keyboard amount
        
        if myKeyboardHeight != 0 {
            view.autoresizingMask  = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
            view.transform = CGAffineTransform(translationX: 0,y: -myKeyboardHeight)
        }
        // Stop responding to keyboard will SHOW notificaions
        unsubscribeFromKeyboardShowNotifications()
        // Begin to respond to keyboard will HIDE notifications
        subscribeToKeyboardHideNotifications()
    }


    // Moves the view down when the keyboard is dismissed
    func keyboardWillHide(_ notification: Notification){
        // Move the bottomTextFiled UIView down by the keyboard amount
        if getKeyboardHeight(notification) != 0 {
            // This allows autolayout in portrait mode, to adjust the Location Textview dynamically. Otherwise the view will autosize and be the incorrect size on screen.
            view.autoresizingMask = UIViewAutoresizing.flexibleWidth
            view.transform = CGAffineTransform(translationX: 0, y: 0)
            
        }
        // This restores the autosizing properties
        view.autoresizingMask  = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        unsubscribeFromKeyboardHideNotifications()
        subscribeToKeyboardShowNotifications()
    }


    // Subscribes to the notification center for keyboard appearances
    func subscribeToKeyboardShowNotifications(){
        // Notify this view controller when keyboard will show
        NotificationCenter.default.addObserver(self, selector: #selector(BeerDetailViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    
    // Subscribes to the notification center for keyboard disappearances
    func subscribeToKeyboardHideNotifications(){
        // Notify this viewcontroller when keyboard will hide
        NotificationCenter.default.addObserver(self, selector: #selector(BeerDetailViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /// Unsubscribes to the notification center for keyboard appearnaces
    func unsubscribeFromKeyboardShowNotifications(){
        // Stop notifying this view controller when the keyboard will show
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    /// Unscubscribes to the notification center for keyboard disappearances
    func unsubscribeFromKeyboardHideNotifications(){
        // Stop notifying this view controller when the keyboard will hide
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
}
