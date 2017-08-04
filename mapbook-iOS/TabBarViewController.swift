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

class TabBarViewController: UITabBarController {

    weak var map:AGSMap?
    weak var locatorTask:AGSLocatorTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let legendViewController = self.viewControllers?[0] as? LegendViewController {
            
            legendViewController.map = self.map
        }
        
        self.delegate = self
    }

}

extension TabBarViewController: UITabBarControllerDelegate {
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if let searchViewController = viewController as? SearchViewController, searchViewController.locatorTask == nil {
            
            searchViewController.locatorTask = self.locatorTask
        }
        else if let bookmarksViewController = viewController as? BookmarksViewController, bookmarksViewController.map == nil {
            
            bookmarksViewController.map = self.map
        }
        
        
        return true
    }
}
