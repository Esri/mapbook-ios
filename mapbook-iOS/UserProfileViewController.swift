//
//  UserProfileViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 8/9/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit

protocol UserProfileViewControllerDelegate:class {
    
    func userProfileViewControllerWantsToSignOut(_ userProfileViewController:UserProfileViewController)
}

class UserProfileViewController: UIViewController {

    @IBOutlet var profileImageView:UIImageView!
    @IBOutlet var usernameLabel:UILabel!
    @IBOutlet var fullnameLabel:UILabel!
    
    weak var delegate:UserProfileViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.preferredContentSize = CGSize(width: 240, height: 150)
        
        self.profileImageView.layer.cornerRadius = 40
        self.profileImageView.layer.masksToBounds = true
        
        guard let portalUser = AppContext.shared.portal?.user else {
            print("Portal user is nil")
            return
        }
        
        self.usernameLabel.text = portalUser.username ?? "<username>"
        self.fullnameLabel.text = portalUser.fullName ?? "<fullname>"
        
        portalUser.thumbnail?.load { [weak self] (error) in
            guard let image = portalUser.thumbnail?.image, error == nil else {
                return
            }
            
            self?.profileImageView.image = image
        }
    }

    
    //MARK: - Actions
    
    @IBAction private func logOut() {
        
        self.dismiss(animated: true, completion: nil)
        
        //notify delegate
        self.delegate?.userProfileViewControllerWantsToSignOut(self)
    }
}
