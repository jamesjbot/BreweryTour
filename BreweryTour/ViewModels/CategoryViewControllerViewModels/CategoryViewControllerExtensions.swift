//
//  CategoryViewControllerExtensions.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/21/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit

// MARK: - BusyObserver

extension CategoryViewController: BusyObserver {

    func registerAsBusyObserverWithMediator() {
        Mediator.sharedInstance().registerForBusyIndicator(observer: self)
    }

    
    func startAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }


    func stopAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }


}

// MARK: - DismissableTutorial

extension CategoryViewController : DismissableTutorial {
    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}

// MARK: - UISearchBarDelegate

extension CategoryViewController: UISearchBarDelegate, AlertWindowDisplaying {

    // Filter out selections not conforming to the searchbar text
    func searchBar(_ searchBar: UISearchBar, textDidChange: String){
        // This will filter empty text too.
        // This is called when the user change text in the searchbar

        if textDidChange.characters.count == 0 {
            // Only dismiss keyboard when removing all characters in the 
            // UISearchbar on an iphone.
            guard UIDevice.current.model == "iPhone" else {
                return
            }
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
        // Refresh the online screen
        activeTableList.filterContentForSearchText(searchText: textDidChange) {
            (ok) -> Void in
            self.genericTable.reloadData()
        }
    }


    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        /*
         Remove searchbar text so we stop searching
         Put searchbar back into unselected state
         Repopulate the table
         */
        newSearchBar.text = ""
        newSearchBar.resignFirstResponder()
        genericTable.reloadData()
    }



    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        /*
         This method allows the user to submit a query to BreweryDB for
         breweries with the searchtext in their name

         Only allow the AllBreweries mode to searchonline for breweries
         this is because when in the styles mode the downloaded brewery
         may not have that style and as such will not show up in the list
         making for a confusing experience.
         Same confusing experience goes for searching for styles.
         */

        // BLOCK ALL ONLINE SEARCHES, except from AllBreweriesTableList
        guard segmentedControl.selectedSegmentIndex == SegmentedControllerMode.AllBreweries.rawValue else {
            return
        }

        // Do nothing, because nothing entered in search bar, just return
        guard !(searchBar.text?.isEmpty)! else {
            return
        }

        // Definition of the inline function to be used in AlertWindow.
        func searchOnline(_ action: UIAlertAction) {

            guard activeTableList is OnlineSearchCapable else {
                return
            }

            guard let onlineSearch : OnlineSearchCapable = activeTableList as! OnlineSearchCapable? else {
                return
            }

            onlineSearch.searchForUserEntered(searchTerm: searchBar.text!) {
                (success, msg) -> Void in

                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                guard success else {
                    self.displayAlertWindow(title: "Search Failed", msg: msg!)
                    return
                }
                self.genericTable.reloadData()
            }
            activityIndicator.startAnimating()
        }


        // Set the function to the action button
        let action = UIAlertAction(title: "Search Online",
                                   style: .default,
                                   handler: searchOnline)
        displayAlertWindow(title: "Search Online",
                           msg: "Dismiss to review the search results\nor press Search Online\nto search for more.",
                           actions: [action])
    }
}


// MARK: - UITableViewDataSource

extension CategoryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = genericTable.dequeueReusableCell(withIdentifier: cellIdentifier)
        // Ask the viewmodel to populate our UITableViewCell
        DispatchQueue.main.async {
            cell = self.activeTableList.cellForRowAt(indexPath: indexPath,
                                                     cell: cell!,
                                                     searchText: self.newSearchBar.text)
            cell?.imageView?.contentMode = .scaleToFill
            cell?.detailTextLabel?.text = ""
            cell?.setNeedsDisplay()
        }
        return cell!
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return activeTableList.getNumberOfRowsInSection(searchText: newSearchBar.text)
    }
}


// MARK: - UITableViewDelegate

extension CategoryViewController : UITableViewDelegate {

    private func createActiveTableListCompletionHandler() -> ((Bool, String?)-> Void) {
        // Create a completion handler for ViewModel to take.
        let activeTableListSelectedCompletionHandler = {
            (success: Bool ,msg: String?) -> Void in
            // Stop the initial start animation a few lines up
            // If and when the brewery process starts.
            // It will invoke it's own start animation sequence
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }

            guard success else {
                self.displayAlertWindow(title: "Error", msg: msg!)
                return
            }

            guard Mediator.sharedInstance().isAutomaticallySegueing() else {
                return
            }

            // User selected a style turn off local breweries
            for viewcontroller in (self.tabBarController?.viewControllers)! {
                if viewcontroller.childViewControllers.first is MapViewController {
                    (viewcontroller.childViewControllers.first as! MapViewController).showLocalBreweries.isOn = false
                    break
                }
            }

            // Move to new tab
            DispatchQueue.main.async {
                self.tabBarController?.selectedIndex = TabbarConstants.mapTab.rawValue
            }

        }
        return activeTableListSelectedCompletionHandler
    }


    // Capture user selections, communicate with the mediator on what the
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Save the selection index
        // Only one selected item can exist at all times
        // This allows us to preload the BreweryTableList
        switch SegmentedControllerMode(rawValue: segmentedControl.selectedSegmentIndex)! {
        case .Style:
            styleSelectionIndex = indexPath

        case .BreweriesWithStyle:
            styleSelectionIndex = nil

        case .AllBreweries:
            styleSelectionIndex = nil

        }

        // Set the Textfield to the name of the selected item so the user
        // knows what they selected.
        selection.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating() // A faster signal to start animating rather than wait for the actual brewery process.
        }

        let completionHandler = createActiveTableListCompletionHandler()

        // Tell the view model something was selected.
        // The view model will go tell the mediator what it needs to download.
        _ = activeTableList.selected(elementAt: indexPath,
                                     searchText: newSearchBar.text!,
                                     completion: completionHandler)
    }
}


// MARK: - Observer

extension CategoryViewController: Observer {

    // Receive notifcation when the TableList backing the current view has changed
    func sendNotify(from: AnyObject, withMsg msg: String) {
        // Only receive messages form the active tablelist

        guard (isViewLoaded && (view.window != nil) ),
            (from === (activeTableList as AnyObject) ) else {
                // Do not process messages when CategoryViewController is not visisble unless you are the stylesTableList.
                return
        }

        // This will update the contents of the table if needed
        switch msg {

        case Message.Reload:
            // Only the active table should respond to a tablelist reload command
            if (activeTableList as AnyObject) === from {
                genericTable.reloadData()
                searchBar(newSearchBar, textDidChange: newSearchBar.text!)
            }
            break
            
        case Message.Retry:
            displayAlertWindow(title: "Error", msg: "Sorry there was an error please try again")
            break
            
        default:
            fatalError("uncaught message \(msg)")
        }
    }
}
