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
 Part of the AppContext that contains all the helper methods
*/
extension AppContext {
    
    /*
     Check if a portal item is already downloaded. Using it
     in the PortalItemCell to change the state of the download
     button.
    */
    func isAlreadyDownloaded(portalItem: AGSPortalItem) -> Bool {
        
        guard let downloadedDirectoryURL = self.downloadDirectoryURL(directoryType: .downloaded) else {
            return false
        }
        
        //check if a mmpk file with itemID as file name exists in the download folder
        let fileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /*
     Check if a portal item is being currently downloaded. Using
     it in the PortalItemCell to switch between activity indicator
     and download button.
    */
    func isCurrentlyDownloading(portalItem: AGSPortalItem) -> Bool {
        return self.currentlyDownloadingItemIDs.contains(portalItem.itemID)
    }
    
    /*
     Check if a local package is being updated. Using it in
     LocalPackageCell to switch between activity indicator
     and download button.
    */
    func isUpdating(package: AGSMobileMapPackage) -> Bool {
        
        //get itemID for package and check if item id is present in 
        //currently downloading items IDs array
        if let itemID = self.itemID(for: package), self.currentlyDownloadingItemIDs.contains(itemID) {
            return true
        }
        
        return false
    }
    
    /*
     Check if a local package is updatable. If the itemID is 
     part of the updatable itemIDs array
     */
    func isUpdatable(package: AGSMobileMapPackage) -> Bool {
        
        if let itemID = self.itemID(for: package) {
            if self.updatableItemIDs.contains(itemID) {
                return true
            }
        }
        
        return false
    }
    
    /*
     Get the index of portal item by using itemID.
    */
    func indexOfPortalItem(withItemID itemID:String) -> Int? {
        
        if let portalItem = self.portalItemWith(itemID: itemID),
            let index = self.portalItems.index(of: portalItem) {
            return index
        }
        return nil
    }
    
    /*
     Get portalItem for itemID.
    */
    func portalItemWith(itemID:String) -> AGSPortalItem? {
        
        let filtered = self.portalItems.filter({ return $0.itemID == itemID })
        
        if filtered.count > 0 {
            return filtered[0]
        }
        else {
            return nil
        }
    }
    
    /*
     Get itemID for a pacakge. The local packages are written to
     the device with itemID as the filename.
    */
    func itemID(for package:AGSMobileMapPackage) -> String? {
        
        if package.fileURL.pathExtension == "mmpk" {
            return package.fileURL.deletingPathExtension().lastPathComponent
        }
        
        return nil
    }
    
    /*
     Get local package with specified itemID. The local packages are written to
     the device with itemID as the filename.
    */
    func localPackage(withItemID itemID: String) -> AGSMobileMapPackage? {
        
        if let index = self.localPackages.index(where: { $0.fileURL.lastPathComponent == "\(itemID).mmpk" }) {
            return self.localPackages[index]
        }
        return nil
    }
    
    /*
     Get size of local package.
    */
    func size(of package:AGSMobileMapPackage) -> String? {
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: package.fileURL.path),
            let size = attributes[FileAttributeKey.size] as? NSNumber {
            
            let bytes = ByteCountFormatter().string(fromByteCount: size.int64Value)
            return bytes
        }
        return nil
    }
    
    /*
     Get download date of local package.
     */
    func downloadDate(of package:AGSMobileMapPackage) -> Date? {
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: package.fileURL.path),
            let date = attributes[FileAttributeKey.creationDate] as? Date {
            
            return date
        }
        return nil
    }
    
    /*
     Get download date of local package as String.
     */
    func downloadDateAsString(of package:AGSMobileMapPackage) -> String? {
        
        if let date = self.downloadDate(of: package) {
            
            let dateString = self.dateFormatter.string(from: date)
            return dateString
        }
        
        return nil
    }
    
    /*
     Get created date of local package as String.
     */
    func createdDateAsString(of item:AGSItem) -> String? {
        
        if let created = item.created {
            let dateString = "\(self.dateFormatter.string(from: created))"
            return dateString
        }
        
        return nil
    }
    
    /*
     Get text to be displayed in the table view if no packages
     found. It varies based on the appMode.
    */
    func textForNoPackages() -> String {
        
        var text:String
        switch AppContext.shared.appMode {
        case .device:
            text = "Add the mobile map package via iTunes and pull to refresh the table view"
        default:
            text = "Tap on the plus button on the right to download mobile map packages from portal. If done downloading pull to refresh the table view"
        }
        
        return text
    }
}
