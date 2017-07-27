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

    // MARK: - Constants
    private let backContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.newBackgroundContext()
    private let maxSaves = 200
    private let timerDelay: Double = 3

    // MARK: - Variables

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


    // MARK: - Functions

    private func decideToDisableTimer() {
        if imagesToBeAssignedQueue.count == 0 {
            // If we finished processing all pending things; stop timer.
            disableTimer()
        }
    }


    // Image processing timer functions
    // Turns off the breweriesToBeProcessed timer
    private func disableTimer() {
        if imageProcessTimer != nil {
            imageProcessTimer?.invalidate()
        }
    }


    private func fetchExecute(request: NSFetchRequest<NSFetchRequestResult>, withKey key: String, inContext context: NSManagedObjectContext?) -> [AnyObject]? {
        // is the Object in Coredata yet
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id == %@", key)
        var result: [AnyObject]?
        do {
            result = try context?.fetch(request)
        } catch {
            NSLog("Critical coredata read problems")
        }
        return result
    }


    private func generateRequest(_ type: ImageDownloadType) -> NSFetchRequest<NSFetchRequestResult> {
        let request: NSFetchRequest<NSFetchRequestResult>?
        switch type {
        case .Beer:
            request = Beer.fetchRequest()
            break
        case .Brewery:
            request = Brewery.fetchRequest()
            break
        }
        return request!
    }


    private func initContext(_ context: NSManagedObjectContext?) {
        context?.automaticallyMergesChangesFromParent = true
        context?.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    internal func queueLinkJob(moID: String, moType: ImageDownloadType, data: NSData) {
        imagesToBeAssignedQueue[moID] = (moType, data)
    }


    // Process the last unfull set on the breweriesToBeProcessed queue.
    @objc private func timerProcessImageQueue() {
        let dq = DispatchQueue.global(qos: .userInitiated)
        let context = backContext
        initContext(context)
        dq.sync {
            var saves = 0 // Stopping counter
            for (key, (type, data ) ) in self.imagesToBeAssignedQueue {
                let request = generateRequest(type)
                let result = fetchExecute(request: request, withKey: key, inContext: context)
                guard result?.count == 1 else  {
                    if result?.count == 0 { // Remove, no parent found
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

                context?.performAndWait { 
                    do {
                        try context!.save()
                    } catch {
                        NSLog("Failed to save context")
                    }
                }

                saves += 1
                self.imagesToBeAssignedQueue.removeValue(forKey: key)
                guard saves < self.maxSaves else {
                    // Block of images updated
                    break
                }
            }
            self.decideToDisableTimer()
        }
    }

}