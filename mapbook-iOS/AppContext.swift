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

extension Notification.Name {
    
    static let DownloadCompleted = Notification.Name("DownloadCompleted")
}

enum AppMode:String {
    case notSet = "NotSet"
    case device = "Device"
    case portal = "Portal"
}

class AppContext {

    static let shared = AppContext()
    
    let DownloadedPackagesDirectoryName = "Downloaded packages"
    
    var appMode:AppMode = .notSet
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
            self.portal?.load(completion: nil)
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
        
        self.appMode = self.determineMode()
    }
    
    //MARK: - Mode related
    
    private func determineMode() -> AppMode {
        
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        //device mode
        //check if documents directory root folder has mmpks
        if let urls = try? FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            
            let mmpkURLs = urls.filter({ return $0.pathExtension == "mmpk" })
            if mmpkURLs.count > 0 {
                return .device
            }
        }
        
        //portal mode
        //if user is logged in
        if self.isUserLoggedIn() {
            return .portal
        }
        
        return AppMode.notSet
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
        
        if self.appMode == .notSet {
            return
        }
        
        //documents directory url
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var directoryURL:URL
        
        if self.appMode == .device {
            directoryURL = documentsDirectoryURL
        }
        else {
            directoryURL = documentsDirectoryURL.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        }
        
        if let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            
            self.localPackageURLs = urls.filter({ return $0.pathExtension == "mmpk" })
            
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
            return
        }
        
        self.localPackageURLs.remove(at: index)
        self.localPackages.remove(at: index)
    }
    
    func deleteAllLocalPackages() {
        
        if self.appMode == .portal {
            guard let downloadDirectoryURL = self.downloadDirectoryURL() else {
                return
            }
            
            do {
                try FileManager.default.removeItem(at: downloadDirectoryURL)
            }
            catch let error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                return
            }
            
            self.localPackages.removeAll()
            self.localPackageURLs.removeAll()
        }
        else {
            for i in (0..<self.localPackageURLs.count).reversed() {
                self.deleteLocalPackage(at: i)
            }
        }
    }
    
    //MARK: - Portal items related
    
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
            self.postDownloadCompletedNotification(userInfo: ["error": error])
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
                self?.postDownloadCompletedNotification(userInfo: ["error": error!])
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Fetch data returned nil as data"])
                self?.postDownloadCompletedNotification(userInfo: ["error": error])
                return
            }
            
            guard let downloadedDirectoryURL = self?.downloadDirectoryURL() else {
                let error = NSError(domain: "com.mapbook", code: 101, userInfo: [NSLocalizedDescriptionKey: "Unable to create directory for downloaded packages"])
                self?.postDownloadCompletedNotification(userInfo: ["error": error])
                return
            }            
            
            let fileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItem.itemID).mmpk")
            
            do {
                try data.write(to: fileURL, options: Data.WritingOptions.atomic)
            }
            catch let error {
                self?.postDownloadCompletedNotification(userInfo: ["error": error])
            }
            
            //success
            self?.postDownloadCompletedNotification(userInfo: ["itemID": portalItem.itemID])
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
    
    private func postDownloadCompletedNotification(userInfo: [AnyHashable : Any]) {
        
        NotificationCenter.default.post(name: .DownloadCompleted, object: self, userInfo: userInfo)
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
    
    func indexOfPortalItem(with itemID:String) -> Int? {
        
        let filtered = self.portalItems.filter({ return $0.itemID == itemID })
        
        if filtered.count > 0, let index = self.portalItems.index(of: filtered[0]) {
            return index
        }
        else {
            return nil
        }
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
