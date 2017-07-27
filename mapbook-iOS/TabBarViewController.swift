//
//  TabBarViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/20/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
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
