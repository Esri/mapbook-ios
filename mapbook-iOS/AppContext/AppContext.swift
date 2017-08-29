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

/*
 Extend Notification.Name to add custom notification name for a package download completion
 */
extension Notification.Name {
    
    static let DownloadCompleted = Notification.Name("DownloadCompleted")
}

/*
 Singleton class that handles all local and portal requests and provide a bunch of helper methods
 */
class AppContext {
    
    //singleton
    static let shared = AppContext()
    
    //name of the directory for saving downloaded packages
    let DownloadedPackagesDirectoryName = "Downloaded packages"
    
    //name of the directory for downloading packages
    let DownloadingPackagesDirectoryName = "Downloading packages"
    
    //current mode of the app
    var appMode:AppMode = .notSet
    
    //list of packages available on device
    var localPackages:[AGSMobileMapPackage] = []
    
    //portal to use for fetching portal items
    var portal:AGSPortal? {
        
        //the portal could be set if 
        //a. user logins first time
        //b. user switches to a different portal
        //c. user logs out (set to nil)
        //d. On app start up, if user was previously logged in
        didSet {
            
            //save the portal url in UserDefaults to instantiate 
            //portal if the app is closed and re-opened
            AppSettings.save(portalUrl: self.portal?.url)
            
            //clean up previous data, if any
            
            //remove all portal items
            self.portalItems.removeAll()
            
            //cancel if previously fetching portal items
            self.fetchPortalItemsCancelable?.cancel()
            
            //new portal is not fetching portal items currently
            self.isFetchingPortalItems = false
            
            //next query is not yet available
            self.nextQueryParameters = nil
            
            //clear list of updatable items, as there may not be any local packages
            self.updatableItemIDs.removeAll()
            
            //cancel all downloads in progress
            _ = self.downloadOperationQueue.operations.map( { $0.cancel() } )
            
            //clear list of currently downloading itemIDs
            self.currentlyDownloadingItemIDs.removeAll()
        }
    }
    
    //list of portalItems from portal
    var portalItems:[AGSPortalItem] = []
    
    //cancelable for the fetch call, in case it needs to be cancelled
    var fetchPortalItemsCancelable:AGSCancelable?
    
    //list of current download operations, in case they need to be cancelled
    //var downloadOperations:[AGSRequestOperation] = []
    
    var downloadOperationQueue = AGSOperationQueue()
    
    //flag if fetching is in progress
    var isFetchingPortalItems = false
    
    //next query parameters returned in the last query
    var nextQueryParameters:AGSPortalQueryParameters?
    
    //date formatter for Date to String conversions
    var dateFormatter:DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()
    
    //list of currently dowloading item's IDs, to show UI accordingly
    var currentlyDownloadingItemIDs:[String] = []
    
    //list of local package's itemIDs, that have an update available online
    var updatableItemIDs:[String] = []
    
    
    /*
     AppContext's private initializer, called only once, since its a 
     singleton class. Called from the AppDelegate's didFinishLaunching
     method the first time. It checks for info on Portal's URL in the
     UserDefaults and instantiates the portal, if available. And then
     determines the app mode.
     */
    private init() {
        
        //if portalURL is stored then instantiate portal object and load it
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
        
        //determine app mode
        self.appMode = self.determineMode()
    }
    
    /*
     The app can be in either one of the three modes:
     a. NotSet - used first time; user logged out; there is no local data and user is logged out
     b. Device - if there are any packages in the documents directory
     c. Portal - if user is logged in to a portal
     The determineMode method uses these conditions to find out the app mode
    */
    private func determineMode() -> AppMode {
        
        //portal mode
        //if user is logged in
        if self.isUserLoggedIn() {
            return .portal
        }
        
        //device mode
        //check if documents directory root folder has mmpks
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let urls = try? FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            
            let mmpkURLs = urls.filter({ return $0.pathExtension == "mmpk" })
            if mmpkURLs.count > 0 {
                return .device
            }
        }
        
        return AppMode.notSet
    }
}
