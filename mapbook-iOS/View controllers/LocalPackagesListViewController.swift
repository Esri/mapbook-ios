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
    @IBOutlet private var noPackagesLabel:UILabel!
    @IBOutlet weak var appModeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self sizing table view cells
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //add refresh control to allow refreshing local packages
        //and check for updates
        self.addRefreshControl()
        
        //update right bar button items based on the mode and state of the app
        self.updateBarButtonItems()
        
        //never show back button
        self.navigationItem.hidesBackButton = true
        
        //for .portal mode, show portal url screen by default if user not logged in
        if AppContext.shared.appMode == .portal && !AppContext.shared.isUserLoggedIn() {
            //show portal URL page
            self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
        }
        
        //add self as observer for DownloadCompleted notification, to update cell
        //state when update completes
        self.observeDownloadCompletedNotification()
        
        //observe changes to app mode
        self.observeAppModeChangeNotification()
        
        //fetch local packages
        self.fetchLocalPackages()
        
        //check for updates
        self.checkForUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateTitleForAppMode()
        
        self.updateSegmentedControlForAppMode()
    }
    
    /*
     Fetch local packages using AppContext.
    */
    private func fetchLocalPackages() {
        
        AppContext.shared.fetchLocalPackages()
        self.tableView.reloadData()
        
        self.showBackgroundLabelIfNeeded()
    }
    
    /*
     Show background label if no packages found.
    */
    fileprivate func showBackgroundLabelIfNeeded() {
        
        if AppContext.shared.localPackages.count > 0 {
            self.noPackagesLabel.isHidden = true
            self.tableView.separatorStyle = .singleLine
        }
        else {
            //set background label
            self.noPackagesLabel.text = AppContext.shared.textForNoPackages()
            self.noPackagesLabel.isHidden = false
            self.tableView.separatorStyle = .none
        }
    }
    
    /*
     Add refresh control to table view. To allow refresh content and check for updates.
    */
    private func addRefreshControl() {
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
    }
    
    /*
     Check for updates for the local packages. Works only for .portal mode.
    */
    private func checkForUpdates() {
        if AppContext.shared.appMode == .portal {
            AppContext.shared.checkForUpdates {
                self.tableView.reloadData()
            }
        }
    }
    
    /*
     Update right bar button items based on the app mode and state. Device 
     mode will only have a button to switch to Portal mode. Portal mode can
     have different buttons based on if the user is logged in or not.
    */
    fileprivate func updateBarButtonItems() {
        
        if AppContext.shared.appMode == .device {
            self.navigationItem.rightBarButtonItems = []
        }
        else {
            if AppContext.shared.isUserLoggedIn() {
                self.navigationItem.rightBarButtonItems = [self.addBBI, self.settingsBBI, self.userProfileBBI]
            }
            else {
                self.navigationItem.rightBarButtonItems = [self.addBBI]
            }
        }
    }
    
    private func updateSegmentedControlForAppMode() {
        appModeSegmentedControl.selectedSegmentIndex = AppContext.shared.appMode.rawValue
    }
    
    private func updateTitleForAppMode() {
        switch AppContext.shared.appMode {
        case .portal:
            title = "My Downloaded Portal Maps"
        case .device:
            title = "My Device Maps"
        }
    }
    
    /*
     Perform segue to PortalItemsListViewController
    */
    fileprivate func showPortalItemsListVC() {
        
        self.performSegue(withIdentifier: "PortalItemsSegue", sender: self)
    }
    
    /*
     A convenient method to observe DownloadCompleted notification. It adds self
     as an observer for the notification. And in the closure, updates the state of
     the LocalPackageCell.
    */
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .DownloadCompleted, object: nil, queue: .main) { [weak self] (notification) in
            
            //get error from notification
            let error = notification.userInfo?["error"] as? Error
            
            //show error to user
            if let error = error as NSError?, error.code != NSUserCancelledError {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            
            //get itemID from notification, then get package for that ID.
            //And get the index to get the corresponding cell from the
            //table view. Then update the state of the cell.
            if let itemID = notification.userInfo?["itemID"] as? String,
                let package = AppContext.shared.localPackage(withItemID: itemID),
                let index = AppContext.shared.localPackages.index(of: package),
                let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? LocalPackageCell {
                
                cell.isUpdating = false
                
                if error == nil {
                    cell.isUpdateAvailable = false
                }
            }
        }
    }
    
    private func observeAppModeChangeNotification() {
        
        NotificationCenter.default.addObserver(forName: .AppModeChanged, object: nil, queue: .main) { [weak self] (_) in
            
            guard let strongSelf = self else { return }
            
            //update the segment control to reflect the current app mode.
            strongSelf.updateSegmentedControlForAppMode()
            
            //update the view controller's title to reflect the current app mode.
            strongSelf.updateTitleForAppMode()
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
            controller.presentationController?.delegate = self
        }
        else if segue.identifier == "UserProfileSegue",
            let controller = segue.destination as? UserProfileViewController {
            
            controller.delegate = self
            controller.presentationController?.delegate = self
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
    
    @IBAction func appModeSegmentControlValueChanged(_ sender: Any) {
        
        guard sender as? UISegmentedControl == appModeSegmentedControl else { return }
        
        guard let newMode = AppMode(rawValue: appModeSegmentedControl.selectedSegmentIndex) else { return }
        
        switch newMode {
        case .device:
            switchToDeviceMode()
        case .portal:
            switchToPortalMode()
        }
    }
    
    private func switchToDeviceMode() {
        
        //show alert controller for confirmation
        let alertController = UIAlertController(title: "Switch to Device mode?", message: "This will delete all the packages you have already downloaded and log you out", preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            //log user out
            AppContext.shared.logoutUser()
            
            //update appMode to .device
            AppContext.shared.appMode = .device
            
            //update bar button items
            self?.updateBarButtonItems()
            
            //fetch packages for new mode
            self?.fetchLocalPackages()
        }
        
        //no action
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func switchToPortalMode() {
        
        //show alert controller for confirmation
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to switch to Portal mode?", preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            //update appMode to .portal
            AppContext.shared.appMode = .portal
            
            //update bar button items
            self?.updateBarButtonItems()
            
            //fetch packages for new mode
            self?.fetchLocalPackages()
        }
        
        //no action
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }

    fileprivate func logout() {
        
        //show confirmation
        let alertController = UIAlertController(title: "Confirm logout?", message: "This will delete all the packages you have already downloaded", preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] (action) in
            
            //log user out
            AppContext.shared.logoutUser()
            
            //pop to initial view controller
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        //no action
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func settings() {
        
        self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
    }
    
    @objc private func refreshControlValueChanged(_ refreshControl: UIRefreshControl) {
        
        //refresh local packages
        self.fetchLocalPackages()
        
        //hide control
        refreshControl.endRefreshing()
        
        //check for updates
        self.checkForUpdates()
    }
    
    deinit {
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
}

extension LocalPackagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppContext.shared.localPackages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocalPackageCell") as? LocalPackageCell else {
            return UITableViewCell()
        }
        
        //local package for cell
        cell.mobileMapPackage = AppContext.shared.localPackages[indexPath.row]
        
        return cell
    }
}

extension LocalPackagesListViewController: UITableViewDelegate {
    
    //for deleting package
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //delete package using AppContext
            AppContext.shared.deleteLocalPackage(at: indexPath.row)
        
            //refresh table view
            tableView.reloadData()
            
            //if no packages left then show the background label
            self.showBackgroundLabelIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "PackageVCSegue", sender: self)
    }
}

extension LocalPackagesListViewController: PortalURLViewControllerDelegate {
    
    func portalURLViewController(_ portalURLViewController: PortalURLViewController, loadedPortalWithError error: Error?) {
        
        //refresh table view as the portal could have been switched and
        //earlier packages might have been deleted
        self.tableView.reloadData()
        
        //update bar button items as the user could be logged in or out now
        self.updateBarButtonItems()
        
        if let error = error {
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
        }
        else {
            //show portal items from portal
            self.showPortalItemsListVC()
        }
    }
}

extension LocalPackagesListViewController: UserProfileViewControllerDelegate {
    
    func userProfileViewControllerWantsToLogOut(_ userProfileViewController: UserProfileViewController) {
        
        self.logout()
    }
}

extension LocalPackagesListViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
