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

@objc protocol PortalURLViewControllerDelegate {
    
    @objc optional func portalURLViewControllerDidLoadPortal(_ portalURLViewController:PortalURLViewController)
}

class PortalURLViewController: UIViewController {

    @IBOutlet private var urlTextField:UITextField!
    
    weak var delegate:PortalURLViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let portal = AppContext.shared.portal, let urlString = portal.url?.absoluteString {
            self.urlTextField.text = urlString
        }
        
    }
    
    private func initializeAndLoadPortal(urlString: String) {
        
        if let portalURL = URL(string: urlString) {
            
            let portal = AGSPortal(url: portalURL, loginRequired: true)
            portal.load { [weak self] (error) in
                
                guard error == nil else {
                    
                    print("Try again")
                    return
                }
                
                AppContext.shared.portal = portal
                
                //show portal items
                self?.dismiss(animated: true) {
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.delegate?.portalURLViewControllerDidLoadPortal?(strongSelf)
                }
            }
        }
    }
    
    private func showAlert(newPortalURLString: String) {
        
        let alertController = UIAlertController(title: "Switch portal?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            AppContext.shared.deleteAllLocalPackages()
            
            self?.initializeAndLoadPortal(urlString: newPortalURLString)
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    //MARK: - Actions
    
    @IBAction private func continueAction(_ sender:UIButton) {
        
        guard let text = self.urlTextField.text else {
            return
        }
        
        if AppContext.shared.portal == nil {
            
            self.initializeAndLoadPortal(urlString: text)
        }
        else {
            
            self.showAlert(newPortalURLString: text)
        }
        
        
    }
    
    @IBAction private func cancel(_ sender:UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
}
