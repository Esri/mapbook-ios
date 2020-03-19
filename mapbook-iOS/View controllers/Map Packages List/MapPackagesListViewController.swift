
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

class MapPackagesListViewController: UIViewController {

    @IBOutlet fileprivate var tableView:UITableView!
    
    @IBOutlet private var portalSearchButton:UIBarButtonItem!
    @IBOutlet private var portalAuthButton:UIBarButtonItem!
    
    // MARK:- Portal Section
    
    private var portalPackages = [PortalAwareMobileMapPackage]()
    private var devicePackages = [AGSMobileMapPackage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self sizing table view cells
        tableView.estimatedRowHeight = 202
        tableView.rowHeight = UITableView.automaticDimension
        
        //add self as observer for DownloadCompleted notification, to update cell
        //state when update completes
        observeDownloadCompletedNotification()
        
        //observe changes to portal
        observePortalChangedNotification()
        
        //ensure navigation item buttons reflect app context state
        updateNavigationItems()
        
        //load and refresh packages downloaded from portal
        fetchDownloadedPortalPackages()
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
        
        NotificationCenter.default
            .addObserver(forName: .downloadDidComplete,
                         object: nil,
                         queue: .main) { [weak self] (notification) in
            
            guard let self = self else { return }
            
            //get error from notification
            if let error = notification.userInfo?["error"] as? NSError,
                error.code != NSUserCancelledError {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            
            self.fetchDownloadedPortalPackages()
        }
    }
    
    private func observePortalChangedNotification() {
        
        NotificationCenter.default
            .addObserver(forName: .portalSessionStatusDidChange,
                         object: nil,
                         queue: .main) { [weak self] (_) in
                            
            guard let self = self else { return }
            
            self.updateNavigationItems()
            self.checkForUpdatesForDownloadedPortalPackages()
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showMapPackage",
            let controller = segue.destination as? MapPackageViewController,
            let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            let package = portalPackages[selectedIndexPath.row]
            controller.mapPackage = package
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        else if segue.identifier == "showBrowsePortal",
            let navigation = segue.destination as? UINavigationController,
            let controller = navigation.topViewController as? PortalItemsListViewController  {
            guard let portal = appContext.sessionManager.portal else {
                preconditionFailure("User must be signed in to an active portal session.")
            }
            controller.packageFinder = PortalPackageSearchManager(portal)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func browsePortalForMapPackages(_ sender:UIBarButtonItem) {
        
        guard case PortalSessionManager.Status.loaded(_) = appContext.sessionManager.status else {
            return
        }
        
        self.performSegue(withIdentifier: "showBrowsePortal", sender: self)
    }
    
    // MARK:- Refresh Downloaded Portal Packages
    
    func fetchDownloadedPortalPackages() {
        do {
            try appContext.packageManager.fetchDownloadedPackages { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let packages):
                    self.finishRefresh(with: packages)
                case .failure(let error):
                    self.failRefresh(with: error)
                }
            }
        }
        catch {
            failRefresh(with: error)
        }
    }
    
    func checkForUpdatesForDownloadedPortalPackages() {
        
        guard appContext.sessionManager.isSignedIn else { return }
        
        do {
            try appContext.packageManager.checkForUpdates(packages: portalPackages) { [weak self] in
                guard let self = self else { return }
                self.finishRefresh(with: self.portalPackages)
            }
        }
        catch {
            failRefresh(with: error)
        }
    }
    
    private func finishRefresh(with packages: [PortalAwareMobileMapPackage]) {
        
        portalPackages = packages
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            self.tableView.reloadData()
                            
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: false) { [weak self] (_) in
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func failRefresh(with error: Error) {
        
        portalPackages.removeAll()
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            self.tableView.reloadData()
            
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: false) { [weak self] (_) in
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    deinit {
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func update() {

    }
}

extension MapPackagesListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // Portal Packages
            return portalPackages.isEmpty ? 1 : portalPackages.count
        }
        else { // Device Packages
            return devicePackages.isEmpty ? 1 : devicePackages.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { // Portal Packages
            return "Portal Packages"
        }
        else { // Device Packages
            return "Device Packages"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        var sectionEmpty = false
        
        if indexPath.section == 0 {
            sectionEmpty = portalPackages.isEmpty
        }
        else {
            sectionEmpty = devicePackages.isEmpty
        }
        
        guard !sectionEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoPackagesCell") as! NoPackagesCell
            return cell
        }
        
        //cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocalPackageCell") as! LocalPackageCell
        
        if indexPath.section == 0 {
            cell.mobileMapPackage = portalPackages[indexPath.row]
        }
        else {
//            cell.mobileMapPackage = portalPackages[indexPath.row]
        }
        
        cell.updateButton.addTarget(self, action: #selector(update), for: .touchUpInside)
        
        return cell
    }
}

extension MapPackagesListViewController: UITableViewDelegate {
    
    //for deleting package
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard editingStyle == .delete else { return } // supports no other form of editing.
        
        //show alert controller for confirmation
        let alertController = UIAlertController(title: nil,
                                                message: "Are you sure you want to delete this mobile map package?",
                                                preferredStyle: .alert)
        
        //yes action
        let yesAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action) in
            
            guard let self = self else { return }
            
            if indexPath.section == 0 { // Portal Packages
                let package = self.portalPackages.remove(at: indexPath.row)
                            
                //delete package from app context
                try? appContext.packageManager.removeDownloaded(package: package)
                
                tableView.reloadSections([indexPath.section], with: .fade)
            }
            else {
                //
            }
        }
        
        //no action
        let noAction = UIAlertAction(title: "No", style: .cancel)
        
        //add actions to alert controller
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.cellForRow(at: indexPath) is NoPackagesCell {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            self.performSegue(withIdentifier: "showMapPackage", sender: self)
        }
    }
}

extension MapPackagesListViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

class NoPackagesCell: UITableViewCell {
    @IBOutlet weak var messageLabel: UILabel!
}

class LocalPackageCell: UITableViewCell {
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static var byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        return formatter
    }()

    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var createdLabel:UILabel!
    @IBOutlet weak var sizeLabel:UILabel!
    @IBOutlet weak var descriptionLabel:UILabel!
    @IBOutlet weak var thumbnailImageView:UIImageView!
    @IBOutlet weak var downloadedLabel:UILabel!
    @IBOutlet weak var updateButton:UIButton!
    @IBOutlet weak var activityIndicatorView:UIActivityIndicatorView!
    @IBOutlet weak var updateStackView:UIStackView!
        
    var isUpdating = false {
        didSet {
            self.updateButton.isHidden = isUpdating
            self.activityIndicatorView?.isHidden = !isUpdating
            
            if !(self.activityIndicatorView?.isHidden ?? true) {
                self.activityIndicatorView?.startAnimating()
            }
        }
    }
    
    var mobileMapPackage: PortalAwareMobileMapPackage? {
        didSet {
            guard let mobileMapPackage = self.mobileMapPackage,
                let item = mobileMapPackage.item else {
                return
            }
                            
            if let itemID = mobileMapPackage.itemID  {
                self.isUpdating = appContext.packageManager.isCurrentlyDownloading(item: itemID)
            }
            else {
                self.isUpdating = false
            }
            if let created = item.created {
                self.createdLabel.text = "Created \(Self.dateFormatter.string(from: created))"
            }
            else {
                self.createdLabel.text = ""
            }
            
            if let size = mobileMapPackage.size {
                self.sizeLabel.text = "Size \(Self.byteFormatter.string(fromByteCount: size))"
            }
            else {
                self.sizeLabel.text = ""
            }
            
            self.titleLabel.text = item.title
            self.descriptionLabel.text = item.snippet
            self.thumbnailImageView.image = item.thumbnail?.image
            
            if let downloadDate = mobileMapPackage.downloadDate {
                self.downloadedLabel.text = Self.dateFormatter.string(from: downloadDate)
            }
            else {
                self.downloadedLabel.text = ""
            }
        }
    }
}
