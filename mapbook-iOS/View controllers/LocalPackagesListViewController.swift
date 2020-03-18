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
    
    @IBOutlet private var portalSearchButton:UIBarButtonItem!
    @IBOutlet private var portalAuthButton:UIBarButtonItem!
    
    private var downloadedPackages = [PortalAwareMobileMapPackage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self sizing table view cells
        tableView.estimatedRowHeight = 84
        tableView.rowHeight = UITableView.automaticDimension
        
        //add refresh control to allow refreshing local packages
        //and check for updates
        self.addRefreshControl()
        
        //add self as observer for DownloadCompleted notification, to update cell
        //state when update completes
        self.observeDownloadCompletedNotification()
        
        //observe changes to app mode
        self.observeAppModeChangeNotification()
        
        //observe changes to portal
        self.observePortalChangedNotification()
        
        //fetch local packages
        self.fetchLocalPackages()
        
        //check for updates
        self.checkForUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //the navigation bar button items should reflect the app mode and portal
        self.updateNavigationItems()
    }
    
    /*
     Fetch local packages using AppContext.
    */
    private func fetchLocalPackages() {
        
        func show(error: Error) {
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
        }
        
        do {
            try appContext.packageManager.fetchDownloadedPackages { [weak self] (result) in
                
                guard let self = self else { return }
                
                switch result {
                case .success(let packages):
                    self.downloadedPackages = packages
                case .failure(let error):
                    show(error: error)
                }
                
                self.tableView.reloadData()
            }
        }
        catch {
            
            show(error: error)
            downloadedPackages.removeAll()
            
            self.tableView.reloadData()
        }
    }
    
    /*
     Add refresh control to table view. To allow refresh content and check for updates.
    */
    private func addRefreshControl() {
        
        //add a refresh control to the table view, triggering a refresh of local packages
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    /*
     Check for updates for the local packages. Works only for .portal mode.
    */
    private func checkForUpdates() {
        try? appContext.packageManager.checkForUpdates(packages: downloadedPackages) {
            self.tableView.reloadData()
        }
    }
    
    private func updateNavigationItems() {
        if case PortalSessionManager.Status.loaded(_) = appContext.sessionManager.status {
            portalSearchButton.isEnabled = true
        }
        else {
            portalSearchButton.isEnabled = false
        }
    }
    /*
     A convenient method to observe DownloadCompleted notification. It adds self
     as an observer for the notification. And in the closure, updates the state of
     the LocalPackageCell.
    */
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .downloadDidComplete, object: nil, queue: .main) { [weak self] (notification) in
            
            guard let strongSelf = self else { return }
            
            //get error from notification
            if let error = notification.userInfo?["error"] as? NSError, error.code != NSUserCancelledError {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            
            strongSelf.refreshLocalPackages()
        }
    }
    
    private func observeAppModeChangeNotification() {
        
        NotificationCenter.default
            .addObserver(forName: .appModeDidChange,
                         object: nil,
                         queue: .main) { [weak self] (_) in
            
            guard let self = self else { return }
            self.updateNavigationItems()
        }
    }
    
    private func observePortalChangedNotification() {
        
        NotificationCenter.default.addObserver(forName: .portalSessionStatusDidChange, object: nil, queue: .main) { [weak self] (_) in
            //the navigation bar button items should reflect the app mode and portal
            self?.updateNavigationItems()
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showMapPackage",
            let controller = segue.destination as? MapPackageViewController,
            let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            let package = downloadedPackages[selectedIndexPath.row]
            controller.mapPackage = package
        }
        else if segue.identifier == "PortalURLSegue",
            let controller = segue.destination as? PortalAccessViewController {
            
            controller.delegate = self
            controller.presentationController?.delegate = self
        }
        else if segue.identifier == "PortalItemsSegue",
            let navigation = segue.destination as? UINavigationController,
            let controller = navigation.topViewController as? PortalItemsListViewController  {
            guard let portal = appContext.sessionManager.portal else {
                preconditionFailure("User must be signed in to an active portal session.")
            }
            controller.packageFinder = PortalPackageSearchManager(portal)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func add(_ sender:UIBarButtonItem) {
        
        if case PortalSessionManager.Status.loaded(_) = appContext.sessionManager.status {
            //show portal items list view controller
            self.performSegue(withIdentifier: "PortalItemsSegue", sender: self)
        }
        else {
            //show portal URL page
            self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
        }
    }

//    fileprivate func signOut() {
//
//        //show confirmation
//        let alertController = UIAlertController(title: "Confirm logout?", message: nil, preferredStyle: .alert)
//
//        //yes action
//        let yesAction = UIAlertAction(title: "Sign out", style: .default) { (_) in
//            appContext.sessionManager.signOut()
//        }
//
//        //no action
//        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
//
//        //add actions to alert controller
//        alertController.addAction(yesAction)
//        alertController.addAction(noAction)
//
//        //present alert controller
//        self.present(alertController, animated: true, completion: nil)
//    }
    
    @IBAction func viewPortalAccessViewController() {
        
        self.performSegue(withIdentifier: "PortalURLSegue", sender: self)
    }
    
    @objc private func refreshControlValueChanged(_ refreshControl: UIRefreshControl) {

        self.refreshLocalPackages()
    }
    
    func refreshLocalPackages() {
        
        //refresh local packages
        self.fetchLocalPackages()
        
        //check for updates
        self.checkForUpdates()
        
        //give pause before end refreshing
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: false) { [weak self] (_) in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }
    
    deinit {
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
}

extension LocalPackagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedPackages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocalPackageCell") as? LocalPackageCell else {
            return UITableViewCell()
        }
        
        //local package for cell
        cell.mobileMapPackage = downloadedPackages[indexPath.row]
        
        return cell
    }
}

extension LocalPackagesListViewController: UITableViewDelegate {
    
    //for deleting package
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //show alert controller for confirmation
            let alertController = UIAlertController(title: nil, message: "Are you sure you want to delete this mobile map package?", preferredStyle: .alert)
            
            //yes action
            let yesAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action) in
                
                guard let self = self else { return }
                
                //delete package using AppContext
                let package = self.downloadedPackages[indexPath.row]
                
                try? appContext.packageManager.removeDownloaded(package: package)
                self.downloadedPackages.remove(at: indexPath.row)
                
                //refresh table view
                tableView.reloadData()
            }
            
            //no action
            let noAction = UIAlertAction(title: "No", style: .cancel)
            
            //add actions to alert controller
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
            //present alert controller
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showMapPackage", sender: self)
    }
}

extension LocalPackagesListViewController: PortalAccessViewControllerDelegate {
    
    func portalURLViewControllerRequestedDismiss(_ portalURLViewController: PortalAccessViewController) {
        //refresh table view as the portal could have been switched and
        //earlier packages might have been deleted
        self.tableView.reloadData()
        portalURLViewController.dismiss(animated: true, completion: nil)
    }
}

extension LocalPackagesListViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
