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

protocol UserProfileViewControllerDelegate:class {
    
    //To notify delegate to log out
    func userProfileViewControllerWantsToLogOut(_ userProfileViewController:UserProfileViewController)
}

class UserProfileViewController: UIViewController {

    @IBOutlet var profileImageView:UIImageView!
    @IBOutlet var usernameLabel:UILabel!
    @IBOutlet var fullnameLabel:UILabel!
    
    weak var delegate:UserProfileViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //preferred content size as pop over
        self.preferredContentSize = CGSize(width: 240, height: 150)
        
        //stylize image view
        self.profileImageView.layer.cornerRadius = 40
        self.profileImageView.layer.masksToBounds = true
        
        //Portal should be loaded in order to get the user
        guard let portalUser = AppContext.shared.portal?.user else {
            print("Portal user is nil")
            return
        }
        
        //update text fields
        self.usernameLabel.text = portalUser.username ?? ""
        self.fullnameLabel.text = portalUser.fullName ?? ""
        
        //load thumbnail on user to get the image
        portalUser.thumbnail?.load { [weak self] (error) in
            guard let image = portalUser.thumbnail?.image, error == nil else {
                return
            }
            
            //add image
            self?.profileImageView.image = image
        }
    }

    
    //MARK: - Actions
    
    @IBAction private func logOut() {
        
        self.dismiss(animated: true, completion: nil)
        
        //notify delegate
        self.delegate?.userProfileViewControllerWantsToLogOut(self)
    }
}
