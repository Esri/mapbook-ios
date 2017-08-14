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
