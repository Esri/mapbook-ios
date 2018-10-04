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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.scheme == AppSettings.appSchema, urlComponents.host == AppSettings.authURLPath {
            
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.setLicenseKey()
        
        self.setupOAuthManager()
                
        self.modifyAppearance()
        
        return true
    }
    
    private func setLicenseKey() {
        
        if !AppSettings.licenseKey.isEmpty {
            do {
                try AGSArcGISRuntimeEnvironment.setLicenseKey(AppSettings.licenseKey)
            }
            catch let error {
                print(error)
            }
        }
    }
    
    private func setupOAuthManager() {
        
        let redirectURL = "\(AppSettings.appSchema)://\(AppSettings.authURLPath)"
        let config = AGSOAuthConfiguration(portalURL: nil, clientID: AppSettings.clientID, redirectURL: redirectURL)
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(withIdentifier: AppSettings.keychainIdentifier, accessGroup: nil, acrossDevices: false)
    }
    
    // MARK: - Appearance modification
    
    func modifyAppearance() {
        
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor.primaryBlue()
        UINavigationBar.appearance().tintColor = UIColor.yellow
        
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.yellow
        UIButton.appearance().tintColor = UIColor.primaryBlue()
        
        UITabBar.appearance().tintColor = UIColor.white
        UITabBar.appearance().barTintColor = UIColor.primaryBlue()

        UISwitch.appearance().onTintColor = UIColor.primaryBlue()
        UISlider.appearance().tintColor = UIColor.primaryBlue()
        
        UISegmentedControl.appearance().tintColor = UIColor.primaryBlue()
        
        UIRefreshControl.appearance().tintColor = UIColor.yellow
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.primaryBlue()
    }
}

extension UIColor {
    
    class func primaryBlue() -> UIColor {
        return UIColor(red: 61.0/255.0, green: 81.0/255.0, blue: 180.0/255.0, alpha: 1)
    }
}

extension Bundle {
    
    private static let agsBundle = AGSBundle()
    
    /// An end-user printable string representation of the ArcGIS Bundle version shipped with the app.
    ///
    /// For example, "2000"
    
    static var sdkBundleVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the ArcGIS Runtime SDK version shipped with the app.
    ///
    /// For example, "100.0.0"
    
    static var sdkVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    /// Builds an end-user printable string representation of the ArcGIS Bundle shipped with the app.
    ///
    /// For example, "ArcGIS Runtime SDK 100.0.0 (2000)"
    
    static var ArcGISSDKVersionString: String {
        return "ArcGIS Runtime SDK \(sdkVersion) (\(sdkBundleVersion))"
    }
}

extension Bundle {
    
    /// An end-user printable string representation of the app display name.
    ///
    /// For example, "Data Collection"
    
    static var appDisplayName: String {
        return (main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the app version number.
    ///
    /// For example, "1.0"
    
    static var appVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the app bundle number.
    ///
    /// For example, "10"
    
    static var appBundleVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    /// Builds an end-user printable string representation of the app name and version.
    ///
    /// For example, "Data Collection 1.0 (10)"
    
    static var AppNameVersionString: String {
        return "\(appDisplayName) \(appVersion) (\(appBundleVersion))"
    }
}

extension AGSPortalInfo {
    
    var appPortalDescription: String? {
        
        var portalDescription: String = ""
        if let organizationName = organizationName {
            portalDescription = organizationName
        }
        if let portalName = portalName {
            if portalDescription.count > 0 {
                portalDescription += "\n"
            }
            portalDescription += portalName
        }
        return portalDescription.count > 0 ? portalDescription : nil
    }
}
