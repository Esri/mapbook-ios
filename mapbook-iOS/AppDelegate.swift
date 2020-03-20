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

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.scheme == AppSettings.appSchema, urlComponents.host == AppSettings.authURLPath {
            
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        buttonAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        navBarAppearance.buttonAppearance = buttonAppearance
        let doneButtonAppearance = UIBarButtonItemAppearance(style: .done)
        doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        doneButtonAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        doneButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.primaryBlue]
        navBarAppearance.doneButtonAppearance = doneButtonAppearance
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        UIButton.appearance().tintColor = .primaryBlue
        
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .primaryBlue

        UISwitch.appearance().onTintColor = .primaryBlue
        UISlider.appearance().tintColor = .primaryBlue
                        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .primaryBlue
    }
}
