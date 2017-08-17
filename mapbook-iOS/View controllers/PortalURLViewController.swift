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

protocol PortalURLViewControllerDelegate:class {
    
    //to notify delegate that portal was loaded successfully
    func portalURLViewControllerDidLoadPortal(_ portalURLViewController:PortalURLViewController)
}

class PortalURLViewController: UIViewController {

    @IBOutlet private var urlTextField:UITextField!
    
    weak var delegate:PortalURLViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //populate portal url string for current portal
        if let portal = AppContext.shared.portal,
            let urlString = portal.url?.absoluteString {
            
            self.urlTextField.text = urlString
        }
    }
    
    /*
     Called either when the user taps on Continue when not logged in
     or when switching portals. The method initializes a portal object
     using provided URL and login required. Loads the portal which
     shows the OAuth page for login. And if login is successful, the
     portal is set on the AppContext and the delegate is notified.
    */
    private func initializeAndLoadPortal(urlString: String) {
        
        guard let portalURL = URL(string: urlString) else {
            return
        }
        
        //initialize portal
        let portal = AGSPortal(url: portalURL, loginRequired: true)
        
        //load portal
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
                
                strongSelf.delegate?.portalURLViewControllerDidLoadPortal(strongSelf)
            }
        }
    }
    
    /*
     Shows an alert for switch portal confirmation. On positive response,
     deletes all local packages and initializes and loads the new portal.
    */
    private func showAlert(newPortalURLString: String) {
        
        //alert controller for confirmation
        let alertController = UIAlertController(title: "Switch portal?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            //delete all local packages as they are associated
            //with the old portal
            AppContext.shared.deleteAllLocalPackages()
            
            //initialize and load new portal
            self?.initializeAndLoadPortal(urlString: newPortalURLString)
        }
        
        //no action
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }

    //MARK: - Actions
    
    /*
     If textfield is not empty and user is not already logged in, then
     initialize and load portal else show alert for confirmation.
    */
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
    
    /*
     Dismiss controller on cancel.
    */
    @IBAction private func cancel(_ sender:UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
}
