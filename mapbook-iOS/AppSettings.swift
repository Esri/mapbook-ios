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
    // Set up AGSLicenseKey in the project's info.plist to remove the Developer watermark.
    // See https://developers.arcgis.com/ios/latest/swift/guide/license-your-app.htm#ESRI_SECTION1_25AC0000E35A4E52B713E8D50359A75C
    static let licenseKey = getAgsSetting(named: "LicenseKey") ?? ""
    
    
    // MARK: - OAuth Logins
    // Set up AppClientID in the project's info.plist. This is used for the OAuth panel and will determine what app users see
    // when they log in to authorize the app to view their account and use their routing/geocoding tasks.
    static let clientID = getAgsSetting(named: "ClientID") ?? ""
    
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
    
    
    // MARK: - User Preferences
    // Determine where user preferences are stored
    static let preferencesStore = UserDefaults.standard
}
