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

protocol PortalAccessViewControllerDelegate:class {
    
    //to notify delegate that portal was loaded
    func portalURLViewController(_ portalURLViewController: PortalAccessViewController, requestsDismissAndShouldShowPortalItemsList shouldShowItems: Bool)
}

class PortalAccessViewController: UIViewController {

    // MARK: IB User Profile Section
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userFullNameLabel: UILabel!
    
    // MARK: IB Portal Section
    @IBOutlet weak var portalInfoLabel: UILabel!
    @IBOutlet private var urlTextField:UITextField!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var appVersionLabel: UILabel!
    
    private var dismissTimer: Timer?
    
    weak var delegate:PortalAccessViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //start observing changes to portal
        observePortalChangedNotification()
        
        //populate portal url string for current portal
        updateForAppContextPortal()
        
        //set app version label string
        setAppVersionLabel()
    }
    
    private func setAppVersionLabel() {
        
        appVersionLabel.text = "\(Bundle.AppNameVersionString)\n\(Bundle.ArcGISSDKVersionString)"
    }
    
    private func observePortalChangedNotification() {
        
        NotificationCenter.default.addObserver(forName: .portalDidChange, object: nil, queue: .main) { [weak self] (_) in
            self?.updateForAppContextPortal()
        }
    }
    
    private func updateForAppContextPortal() {
        
        // Portal is accessed
        if let portal = AppContext.shared.portal {
            
            portal.user?.thumbnail?.load { [weak self] (error) in
                guard error == nil else {
                    print("Could not load user thumbnail image.")
                    self?.userProfileImageView.image = UIImage(named: "Placeholder")
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.userProfileImageView.image = portal.user?.thumbnail?.image ?? UIImage(named: "Placeholder")
                }
            }
            
            userProfileImageView.image = portal.user?.thumbnail?.image ?? UIImage(named: "Placeholder")
            usernameLabel.text = portal.user?.username ?? " "
            userFullNameLabel.text = portal.user?.fullName ?? " "
            urlTextField.isHidden = true
            portalInfoLabel.text = portal.portalInfo?.appPortalDescription ?? "My Organization's Portal"
            urlTextField.text = portal.url?.absoluteString
            urlTextField.isEnabled = false
            actionButton.setTitle("Leave Portal", for: .normal)
        }
        else {
            urlTextField.isHidden = false
            urlTextField.text = "https://www.arcgis.com"
            urlTextField.isEnabled = true
            actionButton.setTitle("Access Portal", for: .normal)
            usernameLabel.text = " "
            userFullNameLabel.text = " "
            userProfileImageView.image = UIImage(named: "Placeholder")
            portalInfoLabel.text = "Specify the URL to your organization or your ArcGIS portal."
        }
    }

    //MARK: - Actions
    
    /*
     If textfield is not empty and user is not already logged in, then
     initialize and load portal else show alert for confirmation.
    */
    @IBAction private func userTappedActionButton(_ sender:UIButton) {
        dismissTimer?.invalidate()
        
        if AppContext.shared.portal == nil {
            accessPortal()
        }
        else {
            leavePortal()
        }
    }
    
    private func accessPortal() {
        
        //ensure the portal URL provided is valid
        guard let text = self.urlTextField.text, let portalURL = URL(string: text) else {
            return
        }
        
        //initialize portal
        let portal = AGSPortal(url: portalURL, loginRequired: true)
        
        //load portal
        portal.load { [weak self] (error) in
            
            guard let strongSelf = self else { return }
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                return
            }
            
            AppContext.shared.portal = portal
            
            //request dismissal from parent view controller request to show portal items list
            strongSelf.triggerTimerToDismissViewController()
        }
    }
    
    private func leavePortal() {
        
        //alert controller for confirmation
        let alertController = UIAlertController(title: "Leave portal?", message: "This will delete all downloaded mobile map packages.", preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Leave", style: .default) { (_) in
            
            //log user out, this will delete existing packages
            AppContext.shared.logoutUser()
        }
        
        //no action
        let noAction = UIAlertAction(title: "Stay", style: .cancel, handler: nil)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func triggerTimerToDismissViewController() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.portalURLViewController(strongSelf, requestsDismissAndShouldShowPortalItemsList: true)
        }
    }
    
    /*
     Dismiss controller on cancel.
    */
    @IBAction private func cancel(_ sender:UIButton) {
        dismissTimer?.invalidate()
        
        delegate?.portalURLViewController(self, requestsDismissAndShouldShowPortalItemsList: false)
    }
    
    deinit {
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
}
