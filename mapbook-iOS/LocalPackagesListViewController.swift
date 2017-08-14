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
    @IBOutlet private var userProfileBBI:UIBarButtonItem!
    @IBOutlet private var settingsBBI:UIBarButtonItem!
    @IBOutlet private var deviceBBI:UIBarButtonItem!
    @IBOutlet private var portalBBI:UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.addRefreshControl()
        
        self.updateBarButtonItems()
        
        //never show back button
        self.navigationItem.hidesBackButton = true
        
        if AppContext.shared.appMode == .portal && !AppContext.shared.isUserLoggedIn() {
            //show portal URL page
            self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
        }
        
        self.observeDownloadCompletedNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchLocalPackages()
    }
    
    private func fetchLocalPackages() {
        
        AppContext.shared.fetchLocalPackages()
        self.tableView.reloadData()
        
        if AppContext.shared.localPackages.count > 0 {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
        }
        else {
            
            //set background label
            self.tableView.backgroundView = labelForTableViewBackground()
            self.tableView.separatorStyle = .none
        }
    }
    
    private func labelForTableViewBackground() -> UILabel {
        
        let label = UILabel()
        label.text = AppContext.shared.appMode == .device ? "Add the mobile map package via iTunes and pull to refresh the table view" : "Tap on the plus button on the right to download mobile map packages from portal. If done downloading pull to refresh the table view"
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        label.numberOfLines = 0
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        label.frame = CGRect(x: label.frame.origin.x, y: label.frame.origin.y, width: 240, height: label.frame.height)
        label.textAlignment = .center
        
        return label
    }
    
    private func addRefreshControl() {
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Checking for updates")
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
    }
    
    fileprivate func updateBarButtonItems() {
        
        if AppContext.shared.appMode == .device {
            self.navigationItem.rightBarButtonItems = [self.portalBBI]
        }
        else {
            if AppContext.shared.isUserLoggedIn() {
                self.navigationItem.rightBarButtonItems = [self.addBBI, self.deviceBBI, self.settingsBBI, self.userProfileBBI]
            }
            else {
                self.navigationItem.rightBarButtonItems = [self.addBBI, self.deviceBBI]
            }
        }
    }
    
    fileprivate func showPortalItemsListVC() {
        
        self.performSegue(withIdentifier: "PortalItemsSegue", sender: self)
    }
    
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .DownloadCompleted, object: nil, queue: .main) { [weak self] (notification) in
            
            let error = notification.userInfo?["error"] as? Error
            
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
            }
            
            if let itemID = notification.userInfo?["itemID"] as? String,
                let package = AppContext.shared.localPackage(withItemID: itemID),
                let index = AppContext.shared.localPackages.index(of: package),
                let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? LocalPackageCell {
                
                cell.isUpdating = false
                
                if error == nil {
                    cell.isUpdateAvailable = false
                    
                    //TODO: update cell
                }
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PackageVCSegue", let controller = segue.destination as? PackageViewController,
            let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            
            let package = AppContext.shared.localPackages[selectedIndexPath.row]
            controller.mobileMapPackage = package
        }
        else if segue.identifier == "PortalURLSegue",
            let controller = segue.destination as? PortalURLViewController {
            
            controller.delegate = self
            controller.preferredContentSize = CGSize(width: 400, height: 300)
        }
        else if segue.identifier == "UserProfileSegue",
            let controller = segue.destination as? UserProfileViewController {
            
            controller.delegate = self
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
    
    @IBAction func switchToDeviceMode() {
        
        let alertController = UIAlertController(title: "Switch to Device mode?", message: "This will delete all the packages you have already downloaded and log you out", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            AppContext.shared.logoutUser()
            AppContext.shared.appMode = .device
            
            self?.tableView.reloadData()
            self?.updateBarButtonItems()
            
            self?.fetchLocalPackages()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func switchToPortalMode() {
        
        let alertController = UIAlertController(title: "Switch to Portal mode?", message: "This will delete all the packages you have on device", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            AppContext.shared.appMode = .portal
            
            self?.tableView.reloadData()
            self?.updateBarButtonItems()
            
            self?.fetchLocalPackages()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    fileprivate func logout() {
        
        let alertController = UIAlertController(title: "Confirm logout?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            AppContext.shared.logoutUser()
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func settings() {
        
        self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
    }
    
    @objc private func refreshControlValueChanged(_ refreshControl: UIRefreshControl) {
        
        self.fetchLocalPackages()
        refreshControl.endRefreshing()
        
        AppContext.shared.checkForUpdates { [weak self] in
            self?.tableView.reloadData()
        }
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

extension LocalPackagesListViewController: UserProfileViewControllerDelegate {
    
    func userProfileViewControllerWantsToSignOut(_ userProfileViewController: UserProfileViewController) {
        
        self.logout()
    }
}
