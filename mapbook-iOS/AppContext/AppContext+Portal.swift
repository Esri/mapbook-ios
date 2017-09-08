//
// Copyright 2017 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts Dept
// 380 New York Street
// Redlands, California, USA 92373
//
// email: contracts@esri.com
//

import Foundation
import ArcGIS


/*
 Part of the AppContext that deals with fetching items, downloading mmpk from Portal. 
 Checks if an update is available for an already downloaded package and updating that
 package.
 */
extension AppContext {
    
    /*
     Fetch portal items from the portal with the seach keyword (if specified). 
     It cancels any request made previously. On completion is returns either an
     error or list of portalItems fetched. It also updates the portalItems array
     on AppContext and saves the nextQueryParameters to fetch the next set of 
     portalItems.
    */
    func fetchPortalItems(using keyword:String?, completion: ((_ error:Error?, _ portalItems:[AGSPortalItem]?) -> Void)?) {
        
        //cancel previous request
        self.fetchPortalItemsCancelable?.cancel()
        
        //clear previous portal items
        self.portalItems = []
        
        //Set query parameters with item type as .mobileMapPackage, search keyword
        //and result limit. The result limit can be set in the Info.plist file.
        let parameters = AGSPortalQueryParameters(forItemsOf: .mobileMapPackage, withSearch: keyword)
        parameters.limit = AppSettings.portalItemQuerySize
        
        //set the state
        self.isFetchingPortalItems = true
        
        //find items
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: parameters) { [weak self] (resultSet, error) in
            
            //set the state
            self?.isFetchingPortalItems = false
            
            //completion with error
            guard error == nil else {
                completion?(error, nil)
                return
            }
            
            //completion with no results
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                print("No portal items found")
                completion?(nil, nil)
                return
            }
            
            //save next query params
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            //set portal items instance variable
            self?.portalItems = portalItems
            
            //call completion
            completion?(nil, portalItems)
        }
    }
    
    /*
     Find out if more portal items are available
    */
    func hasMorePortalItems() -> Bool {
        return self.nextQueryParameters != nil
    }
    
    /*
     Get the next set of portal items. This only works if there is no other 
     fetch request. Determined using isFetchingPortalItems boolean. On completion,
     it returns either error or next set of portalItems. Also updates the ivar by
     appending new values to it. And stores the next query parameter.
    */
    func fetchMorePortalItems(completion: ((_ error:Error?, _ morePortalItems: [AGSPortalItem]?) -> Void)?) {
        
        //Already fetching portal items
        if self.isFetchingPortalItems {
            completion?(nil, nil)
            return
        }
        
        //if next query parameters is nil
        guard let nextQueryParameters = self.nextQueryParameters else {
            completion?(nil, nil)
            return
        }
        
        //set the state
        self.isFetchingPortalItems = true
        
        //find items
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: nextQueryParameters) { [weak self] (resultSet, error) in
            
            //set the state
            self?.isFetchingPortalItems = false
            
            //error
            guard error == nil else {
                completion?(error, nil)
                return
            }
            
            //no result
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                print("No portalItems found")
                completion?(nil, nil)
                return
            }
            
            //save next query params
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            //append to existing items
            self?.portalItems.append(contentsOf: portalItems)
            
            //call completion
            completion?(nil, portalItems)
        }
    }
    
    /*
     Method to download the package from a portal item. An AGSRequestOperation is
     created for download. The packages are first downloaded to the downloading 
     directory and on successful completion they are moved to the downloaded
     directory. It also keeps record of the items being currently downloaded. Once
     done, a DownloadCompleted notification is posted with the itemID of the downloaded
     package. The notification can be used to update UI.
    */
    func download(portalItem: AGSPortalItem) {
        
        //check if already downloading
        if self.isCurrentlyDownloading(portalItem: portalItem) {
            let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Already downloading"])
            self.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
            return
        }
        
        //add to the currently downloading itemIDs list
        self.currentlyDownloadingItemIDs.append(portalItem.itemID)
        
        guard let absoluteString = self.portal?.url?.absoluteString else {
            let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "URL not found"])
            self.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
            return
        }
        
        // Get the URL of the item data on the server
        let itemDataURL = String(format: "%@/sharing/rest/content/items/%@/data", absoluteString, portalItem.itemID)
        
        //Unable to create download directory inside documents directory
        guard let downloadingDirectoryURL = self.downloadDirectoryURL(directoryType: .downloading),
            let downloadedDirectoryURL = self.downloadDirectoryURL(directoryType: .downloaded) else {
                
            let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Unable to create directory for downloading packages"])
            self.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
            return
        }
        
        //Use itemID as the name of the package on device
        let downloadingFileURL = downloadingDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
        let downloadedFileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
        
        let requestOperation = AGSRequestOperation(remoteResource: self.portal, url: URL(string: itemDataURL)!, queryParameters: nil, method: .get)
        
        requestOperation.outputFileURL = downloadingFileURL
        requestOperation.sessionID = portalItem.itemID
        
        requestOperation.registerListener(self) { [weak self] (result, error) in
            
            //remove from currently downloading list
            if let index = self?.currentlyDownloadingItemIDs.index(of: portalItem.itemID) {
                self?.currentlyDownloadingItemIDs.remove(at: index)
            }
            
            guard error == nil else {
                //post notification
                self?.postDownloadCompletedNotification(userInfo: ["error": error!, "itemID": portalItem.itemID])
                
                //delete from downloading folder
                try? FileManager.default.removeItem(at: downloadingFileURL)
                
                return
            }
            
            //clear itemID from updatableItemIDs if it was an update
            if let index = self?.updatableItemIDs.index(of: portalItem.itemID) {
                self?.updatableItemIDs.remove(at: index)
            }
            
            //move item from downloading folder to downloaded folder
            try? FileManager.default.moveItem(at: downloadingFileURL, to: downloadedFileURL)
            
            //success
            self?.postDownloadCompletedNotification(userInfo: ["itemID": portalItem.itemID])
        }
        
        self.downloadOperationQueue.addOperation(requestOperation)
    }
    
    /*
     Get the url to the download directory inside documents directory. Downloading 
     directory for currently downloading packages and Downloaded directory for
     completed downloads. The method returns one if the download directory already
     exists else creates the directory and then returns its URL. And returns nil,
     if it fails to create the download directory.
    */
    func downloadDirectoryURL(directoryType:DirectoryType) -> URL? {
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryName = directoryType == .downloaded ? DownloadedPackagesDirectoryName : DownloadingPackagesDirectoryName
        let directoryURL = documentDirectory.appendingPathComponent(directoryName, isDirectory: true)
        
        //if directory exists then return the url
        var isDirectory:ObjCBool = false
        if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return directoryURL
            }
        }
        
        //else create the directory and then return the url
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
        }
        catch {
            return nil
        }
        
        return directoryURL
    }
    
    /*
     Post download completed notification with userInfo. UserInfo must always
     contain the itemID and any error in case of failure.
    */
    private func postDownloadCompletedNotification(userInfo: [AnyHashable : Any]) {
        
        NotificationCenter.default.post(name: .DownloadCompleted, object: self, userInfo: userInfo)
    }
    
    /*
     Check for updates for all the local packages. The method creates a new portal
     item for each package. Loads it. And then compares the modified date of portal
     item against the downloaded date of the package. If update is available, it adds
     the itemID to the updatableItemIDs array. And calls the completion once done
     with all the packages.
    */
    func checkForUpdates(completion: (() -> Void)?) {
        
        //if portal is nil. Should not be the case
        if self.portal == nil {
            completion?()
            return
        }
        
        //clear updatable item IDs array
        self.updatableItemIDs = []
        
        //use dispatch group to track multiple async completion calls
        let dispatchGroup = DispatchGroup()
        
        //for each package
        for package in self.localPackages {
            
            dispatchGroup.enter()
            
            //create portal item
            guard let portalItem = self.createPortalItem(forPackage: package) else {
                dispatchGroup.leave()
                continue
            }
            
            //load portal item
            portalItem.load { [weak self] (error) in
                
                dispatchGroup.leave()
                
                guard error == nil else {
                    return
                }
                
                //check if updated
                if let downloadedDate = self?.downloadDate(of: package),
                    let modifiedDate = portalItem.modified,
                    modifiedDate > downloadedDate {
                    
                    //add to the list
                    self?.updatableItemIDs.append(portalItem.itemID)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            //call completion once all async calls are completed
            completion?()
        }
    }
    
    /*
     Create portal item for a local package.
    */
    private func createPortalItem(forPackage package:AGSMobileMapPackage) -> AGSPortalItem? {
        
        if let portal = self.portal,
            let itemID = self.itemID(for: package) {
            
            //create portal item
            let portalItem = AGSPortalItem(portal: portal, itemID: itemID)
            return portalItem
        }
        return nil
    }
    
    /*
     Update a local package. This involves creating a portal item for
     the package and then calling download(portalItem:) for that item.
    */
    func update(package: AGSMobileMapPackage) {
        
        //create portal item
        guard let portalItem = self.createPortalItem(forPackage: package) else {
            return
        }
        
        //load portal item
        portalItem.load { [weak self] (error) in
            
            if error == nil {
                //download
                self?.download(portalItem: portalItem)
            }
        }
    }
}
