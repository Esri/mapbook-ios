//
//  PortalURLViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/31/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
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
