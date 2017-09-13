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
import ArcGIS

/*
 Part of the AppContext that contains log in related methods
*/
extension AppContext {
    
    /*
     Check if user is logged in. Based off if portal is set.
    */
    func isUserLoggedIn() -> Bool {
        return (self.portal != nil)
    }
    
    /*
     Log the user out. This involves clearing cached credential.
     Deleting all local packages and setting the portal to nil.
     */
    func logoutUser() {
        
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        self.deleteAllLocalPackages()
        self.portal = nil
    }
}
