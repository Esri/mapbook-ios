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

extension AppContext {
    
    func fetchPortalItems(using keyword:String?, completion: ((_ error:Error?, _ portalItems:[AGSPortalItem]?) -> Void)?) {
        
        //if self.isFetchingPortalItems { return }
        
        //cancel previous request
        self.fetchPortalItemsCancelable?.cancel()
        
        self.portalItems = []
        
        let parameters = AGSPortalQueryParameters(forItemsOf: .mobileMapPackage, withSearch: keyword)
        parameters.limit = 20
        
        self.isFetchingPortalItems = true
        
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: parameters) { [weak self] (resultSet, error) in
            
            self?.isFetchingPortalItems = false
            
            guard error == nil else {
                completion?(error, nil)
                return
            }
            
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                print("No portal items found")
                completion?(nil, nil)
                return
            }
            
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            self?.portalItems = portalItems
            
            completion?(nil, portalItems)
        }
    }
    
    func hasMorePortalItems() -> Bool {
        return self.nextQueryParameters != nil
    }
    
    func fetchMorePortalItems(completion: ((_ error:Error?, _ morePortalItems: [AGSPortalItem]?) -> Void)?) {
        
        if self.isFetchingPortalItems {
            completion?(nil, nil)
            return
        }
        
        guard let nextQueryParameters = self.nextQueryParameters else {
            completion?(nil, nil)
            return
        }
        
        //cancel previous request
        self.fetchPortalItemsCancelable?.cancel()
        
        self.isFetchingPortalItems = true
        
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: nextQueryParameters) { [weak self] (resultSet, error) in
            
            self?.isFetchingPortalItems = false
            
            guard error == nil else {
                completion?(error, nil)
                return
            }
            
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                print("No portalItems found")
                completion?(nil, nil)
                return
            }
            
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            self?.portalItems.append(contentsOf: portalItems)
            
            completion?(nil, portalItems)
        }
    }
    
    func download(portalItem: AGSPortalItem) {
        
        //check if already downloading
        if self.isCurrentlyDownloading(portalItem: portalItem) {
            let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Already downloading"])
            self.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
            return
        }
        
        self.currentlyDownloadingItemIDs.append(portalItem.itemID)
        
        var cancelable:AGSCancelable?
        cancelable = portalItem.fetchData { [weak self] (data, error) in
            
            //remove cancelable from the list
            if let index = self?.fetchDataCancelables.index(where: { $0 === cancelable })  {
                self?.fetchDataCancelables.remove(at: index)
            }
            
            //remove from currently downloading list
            if let index = self?.currentlyDownloadingItemIDs.index(of: portalItem.itemID) {
                self?.currentlyDownloadingItemIDs.remove(at: index)
            }
            
            guard error == nil else {
                self?.postDownloadCompletedNotification(userInfo: ["error": error!, "itemID": portalItem.itemID])
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Fetch data returned nil as data"])
                self?.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
                return
            }
            
            guard let downloadedDirectoryURL = self?.downloadDirectoryURL() else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Unable to create directory for downloaded packages"])
                self?.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
                return
            }
            
            let fileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
            
            do {
                try data.write(to: fileURL, options: Data.WritingOptions.atomic)
            }
            catch let error {
                self?.postDownloadCompletedNotification(userInfo: ["error": error, "itemID": portalItem.itemID])
            }
            
            //clear itemID from updatableItemIDs if it was an update
            if let index = self?.updatableItemIDs.index(of: portalItem.itemID) {
                self?.updatableItemIDs.remove(at: index)
            }
            
            //success
            self?.postDownloadCompletedNotification(userInfo: ["itemID": portalItem.itemID])
        }
        
        if let cancelable = cancelable {
            self.fetchDataCancelables.append(cancelable)
        }
    }
    
    func downloadDirectoryURL() -> URL? {
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadedDirectoryURL = documentDirectory.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        
        
        //if directory exists then return the url
        var isDirectory:ObjCBool = false
        if FileManager.default.fileExists(atPath: downloadedDirectoryURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return downloadedDirectoryURL
            }
        }
        
        //else create the directory and then return the url
        do {
            try FileManager.default.createDirectory(at: downloadedDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        }
        catch {
            return nil
        }
        
        return downloadedDirectoryURL
    }
    
    private func postDownloadCompletedNotification(userInfo: [AnyHashable : Any]) {
        
        NotificationCenter.default.post(name: .DownloadCompleted, object: self, userInfo: userInfo)
    }
    
    func checkForUpdates(completion: (() -> Void)?) {
        
        if self.portal == nil {
            completion?()
            return
        }
        
        self.updatableItemIDs = []
        let dispatchGroup = DispatchGroup()
        
        for package in self.localPackages {
            
            dispatchGroup.enter()
            
            guard let portalItem = self.createPortalItem(forPackage: package) else {
                dispatchGroup.leave()
                continue
            }
            
            portalItem.load { [weak self] (error) in
                
                dispatchGroup.leave()
                
                guard error == nil else {
                    return
                }
                
                if let downloadedDate = self?.downloadDate(of: package),
                    let modifiedDate = portalItem.modified,
                    modifiedDate > downloadedDate {
                    
                    self?.updatableItemIDs.append(portalItem.itemID)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion?()
        }
    }
    
    func update(package: AGSMobileMapPackage) {
        
        guard let portalItem = self.createPortalItem(forPackage: package) else {
            return
        }
        
        portalItem.load { [weak self] (error) in
            
            if error == nil {
                self?.download(portalItem: portalItem)
            }
        }
    }
}
