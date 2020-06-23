//// Copyright 2020 Gagandeep Singh
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

import ArcGIS

class PortalHomeViewController: UITableViewController, BundleAware {
    
    @IBOutlet weak var portalUserThumbnailImageView: UIImageView!
    @IBOutlet weak var portalUserFullNameLabel: UILabel!
    @IBOutlet weak var portalUserEmailLabel: UILabel!
    
    @IBOutlet weak var portalOrgNameLabel: UILabel!
    @IBOutlet weak var portalOrgSubdomainLabel: UILabel!
    @IBOutlet weak var portalOrgIDLabel: UILabel!
    
    @IBOutlet weak var appNameVersionLabel: UILabel!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appNameVersionLabel.text = appNameVersionString
        sdkVersionLabel.text = arcGISSDKVersionString
    }
    
    func configureViewWith(portal: AGSPortal) {
        
        portalUserFullNameLabel.text = portal.user?.fullName
        portalUserEmailLabel.text = portal.user?.email
        
        if let thumbnail = portal.user?.thumbnail {
            
            thumbnail.load { [weak self] (error) in
                
                guard let self = self else { return }
                
                guard error == nil else {
                    self.portalUserThumbnailImageView.isHidden = true
                    return
                }
                
                self.portalUserThumbnailImageView.image = thumbnail.image
            }
        }
        else {
            portalUserThumbnailImageView.isHidden = true
        }
        
        portalOrgNameLabel.text = portal.portalInfo?.organizationName
        portalOrgSubdomainLabel.text = portal.portalInfo?.organizationSubdomain
        portalOrgIDLabel.text = portal.portalInfo?.organizationID
    }
    
    @IBAction func userRequestsSignOutFromPortal(_ sender: AnyObject) {
        appContext.sessionManager.signOut()
    }
}
