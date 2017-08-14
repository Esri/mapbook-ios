//
//  AppContext+Login.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 8/14/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import Foundation
import ArcGIS

extension AppContext {
    
    func isUserLoggedIn() -> Bool {
        return (self.portal != nil)
    }
    
    func logoutUser() {
        
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        AppContext.shared.deleteAllLocalPackages()
        AppContext.shared.portal = nil
    }
}
