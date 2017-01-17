//
//  ManagedObjectImageLinker.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/31/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// Image processing enumeration
internal enum ImageDownloadType {
    case Beer
    case Brewery
}

protocol ImageLinkingProcotol {
    func queueLinkJob(moID: String, moType: ImageDownloadType, data: NSData)
}

class ManagedObjectImageLinker: ImageLinkingProcotol {

    // MARK: Constants

    private let timerDelay: Double = 3
    private let maxSaves = 200

    private let backContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.newBackgroundContext()

    // MARK: Variables

    // Image processing variables
    private var imageProcessTimer: Timer!
    fileprivate var imagesToBeAssignedQueue: [String: (ImageDownloadType, NSData)]
        = [String: (ImageDownloadType,NSData)]() {
        didSet{
            DispatchQueue.main.async {
                self.disableTimer()
                self.imageProcessTimer = Timer.scheduledTimer(timeInterval: self.timerDelay,
                                                              target: self,
                                                              selector: #selector(self.timerProcessImageQueue),
                                                              userInfo: nil, repeats: true)
            }
        }
    }


    // MARK: Functions

    internal func queueLinkJob(moID: String, moType: ImageDownloadType, data: NSData) {
        imagesToBeAssignedQueue[moID] = (moType, data)
    }

    // Image processing timer functions
    // Turns off the breweriesToBeProcessed timer
    private func disableTimer() {
        if imageProcessTimer != nil {
            imageProcessTimer?.invalidate()
        }
    }

    // Process the last unfull set on the breweriesToBeProcessed queue.
    @objc private func timerProcessImageQueue() {
        let dq = DispatchQueue.global(qos: .userInitiated)
        dq.sync {
            var saves = 0 // Stopping counter

            // configure our context
            let context = backContext
            context?.automaticallyMergesChangesFromParent = true
            context?.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            for (key, (type, data ) ) in self.imagesToBeAssignedQueue {
                guard data != nil else { // There is no image remove image request
                    self.imagesToBeAssignedQueue.removeValue(forKey: key)
                    continue
                }
                let request: NSFetchRequest<NSFetchRequestResult>?
                switch type {
                case .Beer:
                    request = Beer.fetchRequest()
                    break
                case .Brewery:
                    request = Brewery.fetchRequest()
                    break
                }
                // is the Object in Coredata yet
                request?.sortDescriptors = []
                request?.predicate = NSPredicate(format: "id == %@", key)
                var result: [AnyObject]?
                do {
                    result = try context?.fetch(request!)

                    guard result?.count == 1 else  {
                        // else try next image
                        // As it currently stand we are guaranteed to have clear
                        // All beers and breweries so if this image is orphaned 
                        // It will be downloaded when the beer or brewery is
                        // downloaded next time.
                        if result?.count == 0                         {
                                self.imagesToBeAssignedQueue.removeValue(forKey: key)
                        }
                        continue
                    }


                    // Currently may ask to replace same image due to unique problem in coredata.
                    switch type {
                    case .Beer:
                        guard (result?.first as! Beer).image == nil else {
                            self.imagesToBeAssignedQueue.removeValue(forKey: key)
                            continue
                        }
                        (result?.first as! Beer).image = data as NSData?
                        break
                    case .Brewery:
                        guard (result?.first as! Brewery).image == nil else {
                            self.imagesToBeAssignedQueue.removeValue(forKey: key)
                            continue
                        }
                        (result?.first as! Brewery).image = data as NSData?
                        break
                    }
                    try context?.save()

                    saves += 1

                    self.imagesToBeAssignedQueue.removeValue(forKey: key)
                } catch {
                    fatalError("Critical coredata read problems")
                }
                guard saves < self.maxSaves else {
                    // Block of images updated
                    Mediator.sharedInstance().broadcastToBreweryImageObservers()
                    break
                }
            }
            if self.imagesToBeAssignedQueue.count == 0 {
                // If we finished processing all pending things; stop timer.
                self.disableTimer()
                // We finished tell people who are interesting in images to reload
                Mediator.sharedInstance().broadcastToBreweryImageObservers()
            }
        }
    }
}
