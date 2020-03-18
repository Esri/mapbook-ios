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

// MARK:- AppMode

extension Notification.Name {
    static let appModeDidChange = Notification.Name("AppModeChanged")
}

var appContext: AppContext { AppContext.shared }

class AppContext {
    
    fileprivate static let shared = AppContext()
    
    private(set) var sessionManager = PortalSessionManager()
    
    private(set) var packageManager = PackageManager()
    
    init() {
        sessionManager.delegate = self
    }
}

// MARK:- Portal Session

extension Notification.Name {
    static let portalSessionStatusDidChange = Notification.Name("PortalSessionStatusDidChange")
}

extension AppContext: PortalSessionManagerDelegate {
    
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status) {
        
        switch status {
        case .loaded(let portal):
            packageManager.portal = portal
        default:
            break
        }
        
        NotificationCenter.default.post(name: .portalSessionStatusDidChange, object: self)
    }
}

// MARK:- Package Manager

extension Notification.Name {
    static let downloadDidComplete = Notification.Name("DownloadDidComplete")
}

extension AppContext: PackageManagerDelegate {
    
    func packageManager(_ manager: PackageManager, failed error: Error, item: AGSPortalItem) {
        NotificationCenter.default.post(name: .downloadDidComplete, object: self, userInfo: ["error": error, "itemID": item.itemID])
    }
    
    func packageManager(_ manager: PackageManager, downloaded item: AGSPortalItem, to path: URL) {
        NotificationCenter.default.post(name: .downloadDidComplete, object: self, userInfo: ["itemID": item.itemID])
    }
}
