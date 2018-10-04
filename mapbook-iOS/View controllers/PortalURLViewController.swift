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
    
    //to notify delegate that portal was loaded
    func portalURLViewController(_ portalURLViewController:PortalURLViewController, loadedPortalWithError error:Error?)
}

class PortalURLViewController: UIViewController {

    // MARK: IB User Profile Section
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userFullNameLabel: UILabel!
    
    // MARK: IB Portal Section
    @IBOutlet private var urlTextField:UITextField!
    @IBOutlet weak var actionButton: UIButton!
    
    weak var delegate:PortalURLViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //start observing changes to portal
        observePortalChangedNotification()
        
        //populate portal url string for current portal
        updateForAppContextPortal()
    }
    
    private func observePortalChangedNotification() {
        
        NotificationCenter.default.addObserver(forName: .PortalDidChange, object: nil, queue: .main) { [weak self] (_) in
            self?.updateForAppContextPortal()
        }
    }
    
    private func updateForAppContextPortal() {
        
        // Portal is accessed
        if let portal = AppContext.shared.portal {
            
            if let user = portal.user {
                
                usernameLabel.text = user.username ?? ""
                userFullNameLabel.text = user.fullName ?? ""
                
                if let thumbnail = user.thumbnail {
                    
                    thumbnail.load { [weak self] (error) in
                        
                        guard let strongSelf = self else { return }
                        
                        guard error == nil, let image = user.thumbnail?.image else {
                            print("Could not load user thumbnail image.")
                            strongSelf.userProfileImageView.image = UIImage(named: "Placeholder")
                            return
                        }
                        
                        strongSelf.userProfileImageView.image = image
                    }
                }
                else {
                    userProfileImageView.image = UIImage(named: "Placeholder")
                }
            }

            urlTextField.text = portal.url?.absoluteString
            urlTextField.isEnabled = false
            actionButton.setTitle("Leave Portal", for: .normal)
        }
        else {
            urlTextField.text = "https://www.arcgis.com"
            urlTextField.isEnabled = true
            actionButton.setTitle("Access Portal", for: .normal)
            usernameLabel.text = ""
            userFullNameLabel.text = ""
            userProfileImageView.image = UIImage(named: "Placeholder")
        }
    }

    //MARK: - Actions
    
    /*
     If textfield is not empty and user is not already logged in, then
     initialize and load portal else show alert for confirmation.
    */
    @IBAction private func continueAction(_ sender:UIButton) {
        
        if AppContext.shared.portal == nil {
            
            //ensure the portal URL provided is valid
            guard let text = self.urlTextField.text, let portalURL = URL(string: text) else {
                return
            }
            
            //initialize portal
            let portal = AGSPortal(url: portalURL, loginRequired: true)
            
            //load portal
            portal.load { [weak self] (error) in
                
                if let error = error, let strongSelf = self {
                    strongSelf.delegate?.portalURLViewController(strongSelf, loadedPortalWithError: error)
                    return
                }
                
                AppContext.shared.portal = portal
                
                //show portal items
                self?.dismiss(animated: true) {
                    if let strongSelf = self {
                        strongSelf.delegate?.portalURLViewController(strongSelf, loadedPortalWithError: nil)
                    }
                }
            }
        }
        else {
            
            //alert controller for confirmation
            let alertController = UIAlertController(title: "Leave portal?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
            
            //yes action
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
                
                //log user out, this will delete existing packages
                AppContext.shared.logoutUser()
            }
            
            //no action
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            
            //add actions to alert controller
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
            //present alert controller
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    /*
     Dismiss controller on cancel.
    */
    @IBAction private func cancel(_ sender:UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
}
