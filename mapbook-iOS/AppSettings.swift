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

struct AppSettings {
    
    private static let agsSettings:[String:Any] = (Bundle.main.infoDictionary?["AGSConfiguration"] as? [String:Any]) ?? [:]
    
    private static func getAgsSetting<T>(named name:String) -> T? {
        return (agsSettings[name] as? T)
    }
    
    // MARK: - Runtime Licensing
    // See https://developers.arcgis.com/ios/latest/swift/guide/license-your-app.htm#ESRI_SECTION1_25AC0000E35A4E52B713E8D50359A75C
    static let licenseKey = "YOUR-LICENSE-KEY"
    
    
    // MARK: - OAuth Logins

    /// The App's public client ID.
    /// - The client ID is used by oAuth to authenticate a user.
    /// - The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    /// - Note: Change this to reflect your organization's client ID.
    static let clientID = "rDLRZg8Xd2siXCDA"
    
    // appScheme and authURLPath are used to tell OAuth how to call back to this app.
    // For example, if they're set up as follows:
    //    AppURLSchema   = "mapbook"
    //    AuthURLPath = "auth"
    // Then the app should register "mapbook" as a URL Type's scheme. And OAuth will call back to mapbook://auth.
    //
    static let appSchema = getAgsSetting(named: "AppURLScheme") ?? "mapbook"
    static let authURLPath = getAgsSetting(named: "AuthURLPath") ?? "auth"
    
    
    // MARK: - Runtime Keychain Integration
    static let keychainIdentifier = getAgsSetting(named: "KeychainIdentifier") ?? "com.mapbook"
    
    
    // MARK: - Portal Basemap Group Querying
    // How many portalItems to get back in a single items query
    // Can help to avoid loading multiple pages of results
    static let portalItemQuerySize:Int = getAgsSetting(named: "PortalItemQuerySize") ?? 20
    
    // MARK: - Portal Default URL String
    // When a user attempts to access a Portal, this URL string defaults in `PortalAccessViewController`
    // Change the cooresponding value in Info.plist to configure your own default
    // Falls back to arcgis online
    static let defaultPortalURLString: String = getAgsSetting(named: "DefaultPortalURLString") ?? URL.arcGISOnline.absoluteString
    
    // MARK: - User Preferences
    // Store and retrieve latest portal URL
    static func save(portalUrl url:URL?) {
        UserDefaults.standard.set(url, forKey: "PORTALURL")
    }
    
    static func getPortalURL() -> URL? {
        return UserDefaults.standard.url(forKey: "PORTALURL")
    }
}
