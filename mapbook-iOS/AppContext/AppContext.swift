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
    var localPackages = [PortalAwareMobileMapPackage]()
    
    var portalSession = PortalSessionManager()
    
    var portalDeviceSync: PackageSyncManager?
    
    init() {
        portalSession.delegate = self
    }
}

extension Notification.Name {
    static let portalSessionStatusDidChange = Notification.Name("PortalSessionStatusDidChange")
}

extension AppContext: PortalSessionManagerDelegate {
    
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status) {
        
        switch status {
        case .loaded(let portal):
            portalDeviceSync = PackageSyncManager(portal: portal)
            portalDeviceSync?.delegate = self
        default:
            portalDeviceSync = nil
        }
        
        NotificationCenter.default.post(name: .portalSessionStatusDidChange, object: self)
    }
}

extension AppContext: PackageSyncManagerDelegate {
    
    func packageSyncManager(_ manager: PackageSyncManager, failed error: Error, item: AGSPortalItem) {
        NotificationCenter.default.post(name: .downloadDidComplete, object: self, userInfo: ["error": error, "itemID": item.itemID])
    }
    
    func packageSyncManager(_ manager: PackageSyncManager, downloaded item: AGSPortalItem, to path: URL) {
        NotificationCenter.default.post(name: .downloadDidComplete, object: self, userInfo: ["itemID": item.itemID])
    }
}
