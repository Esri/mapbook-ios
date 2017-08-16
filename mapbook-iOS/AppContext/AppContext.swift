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

class AppContext {
    
    static let shared = AppContext()
    
    let DownloadedPackagesDirectoryName = "Downloaded packages"
    var appMode:AppMode = .notSet
    var localPackages:[AGSMobileMapPackage] = []
    
    var portal:AGSPortal? {
        didSet {
            
            AppSettings.save(portalUrl: self.portal?.url)
            
            //clean up
            self.portalItems.removeAll()
            self.currentlyDownloadingItemIDs.removeAll()
            self.isFetchingPortalItems = false
            self.fetchPortalItemsCancelable?.cancel()
            self.nextQueryParameters = nil
            self.fetchPortalItemsCancelable?.cancel()
            self.updatableItemIDs.removeAll()
            
            _ = self.fetchDataCancelables.map( { $0.cancel() } )
            self.fetchDataCancelables.removeAll()
        }
    }
    
    var portalItems:[AGSPortalItem] = []
    
    var fetchPortalItemsCancelable:AGSCancelable?
    var fetchDataCancelables:[AGSCancelable] = []
    var isFetchingPortalItems = false
    var nextQueryParameters:AGSPortalQueryParameters?
    
    var dateFormatter:DateFormatter
    
    var currentlyDownloadingItemIDs:[String] = []
    var updatableItemIDs:[String] = []
    
    private init() {
        
        if let portalURL = AppSettings.getPortalURL() {
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
}
