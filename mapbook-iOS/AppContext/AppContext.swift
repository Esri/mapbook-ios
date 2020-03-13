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
    
    static let downloadDidComplete = Notification.Name("DownloadDidComplete")
    static let appModeDidChange = Notification.Name("AppModeChanged")
}

/*
 Singleton class that handles all local and portal requests and provide a bunch of helper methods
 */
class AppContext {
    
    //singleton
    static let shared = AppContext()
    
    //current mode of the app
    var appMode: AppMode = AppMode.retrieveFromUserDefaults() {
        didSet {
            //post change to app mode
            NotificationCenter.default.post(name: .appModeDidChange, object: self, userInfo: nil)
            
            //save new mode to defaults
            appMode.saveToUserDefaults()
        }
    }
    
    //list of packages available on device
    var localPackages:[AGSMobileMapPackage] = []
    
    var portalSession = PortalSessionManager()
//    //portal to use for fetching portal items
//    var portal:AGSPortal? {
//
//        //the portal could be set if
//        //a. user signs in the first time
//        //b. user switches to a different portal
//        //c. user signs out (set to nil)
//        //d. on app start up, if user was previously signed in
//        didSet {
//
//            //save the portal url in UserDefaults to instantiate
//            //portal if the app is closed and re-opened
//            AppSettings.save(portalUrl: self.portal?.url)
//
//            //clean up previous data, if any
//
//            //remove all portal items
//            self.portalItems.removeAll()
//
//            //cancel if previously fetching portal items
//            self.fetchPortalItemsCancelable?.cancel()
//
//            //new portal is not fetching portal items currently
//            self.isFetchingPortalItems = false
//
//            //next query is not yet available
//            self.nextQueryParameters = nil
//
//            //clear list of updatable items, as there may not be any local packages
//            self.updatableItemIDs.removeAll()
//
//            //cancel all downloads in progress
//            self.downloadOperationQueue.operations.forEach { $0.cancel() }
//
//            //clear list of currently downloading itemIDs
//            self.currentlyDownloadingItemIDs.removeAll()
//
//            //post notification of change.
//            NotificationCenter.default.post(name: .portalDidChange, object: self, userInfo: nil)
//        }
//    }
    
    //list of portalItems from portal
    var portalItems:[AGSPortalItem] = []
    
    //cancelable for the fetch call, in case it needs to be cancelled
    var fetchPortalItemsCancelable:AGSCancelable?
    
    var downloadOperationQueue = AGSOperationQueue()
    
    //flag if fetching is in progress
    var isFetchingPortalItems = false
    
    //next query parameters returned in the last query
    var nextQueryParameters:AGSPortalQueryParameters?
    
    //list of currently dowloading item's IDs, to show UI accordingly
    var currentlyDownloadingItemIDs:[String] = []
    
    //list of local package's itemIDs, that have an update available online
    var updatableItemIDs:[String] = []
    
    init() {
        portalSession.delegate = self
    }
}

extension Notification.Name {
    static let portalSessionStatusDidChange = Notification.Name("PortalSessionStatusDidChange")
}

extension AppContext: PortalSessionManagerDelegate {
    
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status) {
        NotificationCenter.default.post(name: .portalSessionStatusDidChange, object: self)
    }
}
