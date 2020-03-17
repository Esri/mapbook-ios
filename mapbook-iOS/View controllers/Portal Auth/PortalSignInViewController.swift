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

class PortalSignInViewController: UITableViewController {
    
    @IBOutlet weak var enterpriseURLTextField: UITextField!
    
    @IBAction func userRequestsSignInToAGOL(_ sender: AnyObject) {
        let agol = AGSPortal.arcGISOnline(withLoginRequired: true)
        appContext.sessionManager.signIn(to: agol) { (_) in }
    }
    
    @IBAction func userRequestsSignInToEnterprise(_ sender: AnyObject) {
        guard
            let urlString = enterpriseURLTextField.text,
            let url = URL(string: urlString) else {
                SVProgressHUD.showError(withStatus: InvalidURL().localizedDescription)
                return
        }
        let enterprise = AGSPortal(url: url, loginRequired: true)
        appContext.sessionManager.signIn(to: enterprise) { (_) in }
    }
    
    private struct InvalidURL: LocalizedError {
        let localizedDescription: String = "Invalid URL"
    }
}

class PortalSignOutViewController: UITableViewController {
    
    @IBAction func userRequestsSignOutFromPortal(_ sender: AnyObject) {
        appContext.sessionManager.signOut()
    }
}
