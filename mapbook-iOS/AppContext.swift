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

import UIKit
import ArcGIS

class AppContext {

    static let shared = AppContext()
    
    let DownloadedPackagesDirectoryName = "Downloaded packages"
    
    var localPackageURLs:[URL] = []
    var localPackages:[AGSMobileMapPackage] = []
    
    var portal:AGSPortal? {
        didSet {
            
            UserDefaults.standard.set(self.portal?.url, forKey: "PORTALURL")
            
            //clean up
            self.portalItems.removeAll()
            self.currentlyDownloadingItemIDs.removeAll()
            self.isFetchingPortalItems = false
            self.fetchPortalItemsCancelable?.cancel()
            self.nextQueryParameters = nil
            self.fetchPortalItemsCancelable?.cancel()
            
            _ = self.fetchDataCancelables.map( { $0.cancel() } )
            self.fetchDataCancelables.removeAll()
        }
    }
    
    var portalItems:[AGSPortalItem] = []
    
    private var fetchPortalItemsCancelable:AGSCancelable?
    private var fetchDataCancelables:[AGSCancelable] = []
    private var isFetchingPortalItems = false
    private var nextQueryParameters:AGSPortalQueryParameters?
    
    private var dateFormatter:DateFormatter
    
    fileprivate var currentlyDownloadingItemIDs:[String] = []
    
    private init() {
    
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(withIdentifier: "com.mapbook", accessGroup: nil, acrossDevices: false)
        
        if let portalURL = UserDefaults.standard.url(forKey: "PORTALURL") {
            self.portal = AGSPortal(url: portalURL, loginRequired: true)
        }
        else {
            //remove credential - special case
            //when app is deleted, the credential is not removed from the keychain
            //and portal load works on re-install w/o the need of OAuth
            //For new install or logged out, PORTALURL wont be there, so clear the credential
            AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        }
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .short
    }
    
    //MARK: - Login related
    
    func isUserLoggedIn() -> Bool {
        return (self.portal != nil)
    }
    
    func logoutUser() {
        
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        AppContext.shared.deleteAllLocalPackages()
        AppContext.shared.portal = nil
    }
    
    //MARK: - Local packages related
    
    func fetchLocalPackageURLs() {
        
        self.localPackageURLs = []
        
        //documents directory url
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadedDirectoryURL = documentsDirectory.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        
        //filter mmpk urls from documents directory
        if let enumerator = FileManager.default.enumerator(at: downloadedDirectoryURL, includingPropertiesForKeys: nil) {
            
            while let url = enumerator.nextObject() as? URL {
                self.localPackageURLs.append(url)
            }
        }
    }
    
    func fetchLocalPackages() {
        
        self.fetchLocalPackageURLs()
        
        self.localPackages = []
        
        //create AGSMobileMapPackage for each url
        for url in localPackageURLs {
            let package = AGSMobileMapPackage(fileURL: url)
            self.localPackages.append(package)
        }
    }
    
    func deleteLocalPackage(at index:Int) {
        
        do {
            try FileManager.default.removeItem(at: self.localPackageURLs[index])
        }
        catch let error {
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
        }
        
        self.localPackageURLs.remove(at: index)
        self.localPackages.remove(at: index)
    }
    
    func deleteAllLocalPackages() {
        
        guard let downloadDirectoryURL = self.downloadDirectoryURL() else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: downloadDirectoryURL)
        }
        catch let error {
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
        }
        
        self.localPackages.removeAll()
        self.localPackageURLs.removeAll()
    }
    
    //MARK: - Portal items related
    
    func fetchPortalItems(completion: ((_ error:Error?) -> Void)?) {
        
        //if self.isFetchingPortalItems { return }
        
        //cancel previous request
        self.fetchPortalItemsCancelable?.cancel()
            
        self.portalItems = []
        
        let parameters = AGSPortalQueryParameters(forItemsOf: .mobileMapPackage, withSearch: nil)
        parameters.limit = 20
        
        self.isFetchingPortalItems = true
        
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: parameters) { [weak self] (resultSet, error) in
            
            self?.isFetchingPortalItems = false
            
            guard error == nil else {
                completion?(error)
                return
            }
            
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                SVProgressHUD.showError(withStatus: "No portal items found", maskType: .gradient)
                return
            }
            
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            self?.portalItems = portalItems
            
            completion?(nil)
        }
    }
    
    func fetchMorePortalItems(completion: ((_ error:Error?) -> Void)?) {
        
        if self.isFetchingPortalItems { return }
        
        guard let nextQueryParameters = self.nextQueryParameters else {
            return
        }
        
        //cancel previous request
        self.fetchPortalItemsCancelable?.cancel()
        
        self.isFetchingPortalItems = true
        
        self.fetchPortalItemsCancelable = self.portal?.findItems(with: nextQueryParameters) { [weak self] (resultSet, error) in
            
            self?.isFetchingPortalItems = false
            
            guard error == nil else {
                completion?(error)
                return
            }
            
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                SVProgressHUD.showError(withStatus: "No portal items found", maskType: .gradient)
                return
            }
            
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            self?.portalItems.append(contentsOf: portalItems)
            
            completion?(nil)
        }
    }
    
    func download(portalItem: AGSPortalItem, completion: ((_ error:Error?) -> Void)?) {
        
        //check if already downloading
        if self.isCurrentlyDownloading(portalItem: portalItem) {
            let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Already downloading"])
            completion?(error)
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
                completion?(error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Fetch data returned nil as data"])
                completion?(error)
                return
            }
            
            guard let downloadedDirectoryURL = self?.downloadDirectoryURL() else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Unable to create directory for downloaded packages"])
                completion?(error)
                return
            }
            
            let fileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
            
            do {
                try data.write(to: fileURL, options: Data.WritingOptions.atomic)
            }
            catch let error {
                completion?(error)
            }
            
            //success
            completion?(nil)
        }
        
        if let cancelable = cancelable {
            self.fetchDataCancelables.append(cancelable)
        }
    }
    
    private func downloadDirectoryURL() -> URL? {
        
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
    
    //MARK: - Helper methods
    
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
    
    func size(of package:AGSMobileMapPackage) -> String? {
        
        if let index = self.localPackages.index(of: package) {
            
            let fileURL = self.localPackageURLs[index]
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                let size = attributes[FileAttributeKey.size] as? NSNumber {
                
                let bytes = ByteCountFormatter().string(fromByteCount: size.int64Value)
                return bytes
            }
        }
        
        return nil
    }
    
    func downloadDate(of package:AGSMobileMapPackage) -> String? {
        
        if let index = self.localPackages.index(of: package) {
            
            let fileURL = self.localPackageURLs[index]
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                let date = attributes[FileAttributeKey.creationDate] as? Date {
                
                let dateString = self.dateFormatter.string(from: date)
                return dateString
            }
        }
        
        return nil
    }
    
    func createdDate(of item:AGSItem) -> String? {
        
        if let created = item.created {
            let dateString = "\(self.dateFormatter.string(from: created))"
            return dateString
        }
        
        return nil
    }    
    
//    func checkForUpdates() {
//    
//        if let itemID = self.localPackages[0].item?.itemID {
//            print(itemID)
//            let portalItem = AGSPortalItem(portal: self.portal!, itemID: itemID)
//            
//            portalItem.load { (error) in
//                //print(portalItem.modified)
//            }
//        }
//    }
}
