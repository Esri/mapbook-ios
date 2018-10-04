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
        
        UIButton.appearance().tintColor = UIColor.primaryBlue()

        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor.primaryBlue()
        UINavigationBar.appearance().tintColor = UIColor.yellow
        
        UITabBar.appearance().tintColor = UIColor.white
        UITabBar.appearance().barTintColor = UIColor.primaryBlue()

        UISwitch.appearance().onTintColor = UIColor.primaryBlue()
        UISlider.appearance().tintColor = UIColor.primaryBlue()
        
        UISegmentedControl.appearance().tintColor = UIColor.primaryBlue()
        
        UIRefreshControl.appearance().tintColor = UIColor.yellow
        
    }
}

extension UIColor {
    
    class func primaryBlue() -> UIColor {
        return UIColor(red: 61.0/255.0, green: 81.0/255.0, blue: 180.0/255.0, alpha: 1)
    }
}

