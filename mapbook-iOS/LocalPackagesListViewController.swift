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

class LocalPackagesListViewController: UIViewController {

    @IBOutlet fileprivate var tableView:UITableView!
    @IBOutlet private var addBBI:UIBarButtonItem!
    @IBOutlet private var logoutBBI:UIBarButtonItem!
    @IBOutlet private var portalBBI:UIBarButtonItem!
    
    private var portalItemsListVC:PortalItemsListViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Checking for updates")
        tableView.refreshControl?.addTarget(self, action: #selector(LocalPackagesListViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        self.portalItemsListVC = self.storyboard?.instantiateViewController(withIdentifier: "PortalItemsListViewController") as? PortalItemsListViewController
        
        self.updateBarButtonItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppContext.shared.fetchLocalPackages()
        self.tableView.reloadData()
    }
    
    fileprivate func updateBarButtonItems() {
        
        if AppContext.shared.isUserLoggedIn() {
            self.navigationItem.rightBarButtonItems = [self.addBBI, self.portalBBI, self.logoutBBI]
        }
        else {
            self.navigationItem.rightBarButtonItems = [self.addBBI]
        }
    }
    
    fileprivate func showPortalItemsListVC() {
        if let portalItemsListVC = self.portalItemsListVC {
            self.show(portalItemsListVC, sender: self)
        }
        else {
            SVProgressHUD.showError(withStatus: "PortalItemsVC is nil. Not possible!", maskType: .gradient)
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PackageVCSegue", let controller = segue.destination as? PackageViewController, let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            
            let package = AppContext.shared.localPackages[selectedIndexPath.row]
            controller.mobileMapPackage = package
        }
        else if segue.identifier == "PortalURLSegue", let controller = segue.destination as? PortalURLViewController {
            controller.delegate = self
            controller.preferredContentSize = CGSize(width: 400, height: 300)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func add(_ sender:UIBarButtonItem) {
        
        if AppContext.shared.isUserLoggedIn() {
            //show portal items list view controller
            self.showPortalItemsListVC()
        }
        else {
            //show portal URL page
            self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
        }
    }

    @IBAction func logout() {
        
        let alertController = UIAlertController(title: "Confirm logout?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            AppContext.shared.logoutUser()
            
            self?.tableView.reloadData()
            
            self?.updateBarButtonItems()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func portalBBIAction() {
        
        self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
    }
    
    @objc private func refreshControlValueChanged(_ refreshControl: UIRefreshControl) {
        
        //AppContext.shared.checkForUpdates()
        
        AppContext.shared.fetchLocalPackages()
        self.tableView.reloadData()

        refreshControl.endRefreshing()
    }
}

extension LocalPackagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppContext.shared.localPackages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocalPackageCell") as? LocalPackageCell else {
            return UITableViewCell()
        }
        
        cell.mobileMapPackage = AppContext.shared.localPackages[indexPath.row]
        return cell
    }
}

extension LocalPackagesListViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            AppContext.shared.deleteLocalPackage(at: indexPath.row)
            
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "PackageVCSegue", sender: self)
    }
}

extension LocalPackagesListViewController: PortalURLViewControllerDelegate {
    
    func portalURLViewControllerDidLoadPortal(_ portalURLViewController: PortalURLViewController) {
        
        self.updateBarButtonItems()
        
        self.tableView.reloadData()
        
        self.showPortalItemsListVC()
    }
}
