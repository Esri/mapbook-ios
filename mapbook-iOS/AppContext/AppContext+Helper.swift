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
    
    func isAlreadyDownloaded(portalItem: AGSPortalItem) -> Bool {
        
        guard let downloadDirectoryURL = self.downloadDirectoryURL() else {
            return false
        }
        
        //check if a mmpk file with itemID as file name exists in the download folder
        let fileURL = downloadDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func isCurrentlyDownloading(portalItem: AGSPortalItem) -> Bool {
        return self.currentlyDownloadingItemIDs.contains(portalItem.itemID)
    }
    
    func isUpdating(package: AGSMobileMapPackage) -> Bool {
        
        if let itemID = self.itemID(for: package), self.currentlyDownloadingItemIDs.contains(itemID) {
            return true
        }
        
        return false
    }
    
    func indexOfPortalItem(withItemID itemID:String) -> Int? {
        
        let filtered = self.portalItems.filter({ return $0.itemID == itemID })
        
        if filtered.count > 0, let index = self.portalItems.index(of: filtered[0]) {
            return index
        }
        else {
            return nil
        }
    }
    
    func portalItemWith(itemID:String) -> AGSPortalItem? {
        
        let filtered = self.portalItems.filter({ return $0.itemID == itemID })
        
        if filtered.count > 0 {
            return filtered[0]
        }
        else {
            return nil
        }
    }
    
    func size(of package:AGSMobileMapPackage) -> String? {
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: package.fileURL.path),
            let size = attributes[FileAttributeKey.size] as? NSNumber {
            
            let bytes = ByteCountFormatter().string(fromByteCount: size.int64Value)
            return bytes
        }
        return nil
    }
    
    func downloadDate(of package:AGSMobileMapPackage) -> Date? {
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: package.fileURL.path),
            let date = attributes[FileAttributeKey.creationDate] as? Date {
            
            return date
        }
        return nil
    }
    
    func downloadDateAsString(of package:AGSMobileMapPackage) -> String? {
        
        if let date = self.downloadDate(of: package) {
            
            let dateString = self.dateFormatter.string(from: date)
            return dateString
        }
        
        return nil
    }
    
    func createdDateAsString(of item:AGSItem) -> String? {
        
        if let created = item.created {
            let dateString = "\(self.dateFormatter.string(from: created))"
            return dateString
        }
        
        return nil
    }
    
    func isUpdatable(package: AGSMobileMapPackage) -> Bool {
        
        if let itemID = self.itemID(for: package) {
            if self.updatableItemIDs.contains(itemID) {
                return true
            }
        }
        
        return false
    }
    
    func createPortalItem(forPackage package:AGSMobileMapPackage) -> AGSPortalItem? {
        
        if let portal = self.portal,
            let itemID = self.itemID(for: package) {
            
            //create portal item
            let portalItem = AGSPortalItem(portal: portal, itemID: itemID)
            return portalItem
        }
        return nil
    }
    
    func itemID(for package:AGSMobileMapPackage) -> String? {
        
        if package.fileURL.pathExtension == "mmpk" {
            return package.fileURL.deletingPathExtension().lastPathComponent
        }
        
        return nil
    }
    
    func localPackage(withItemID itemID: String) -> AGSMobileMapPackage? {
        
        if let index = self.localPackages.index(where: { $0.fileURL.lastPathComponent == "\(itemID).mmpk" }) {
            return self.localPackages[index]
        }
        return nil
    }
}
