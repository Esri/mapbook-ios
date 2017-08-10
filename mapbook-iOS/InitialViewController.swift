//
//  InitialViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 8/8/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class InitialViewController: UIViewController {

    @IBOutlet var deviceParentView:UIView!
    @IBOutlet var portalParentView:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //stylize
        self.deviceParentView.layer.cornerRadius = 10
        self.portalParentView.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.deviceParentView.backgroundColor = UIColor.white
        self.portalParentView.backgroundColor = UIColor.white
    }

    
    //MARK: - Actions
    
    @IBAction private func buttonTouchDown(_ sender:UIButton) {
        let selectedView = (sender.tag == 0) ? self.deviceParentView : self.portalParentView
        selectedView?.backgroundColor = UIColor.yellow
        
        AppContext.shared.appMode = (sender.tag == 0) ? .device : .portal
        
        self.performSegue(withIdentifier: "LocalPackagesListVC", sender: self)
    }
}
