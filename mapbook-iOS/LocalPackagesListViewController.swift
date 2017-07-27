//
//  LocalPackagesListViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/25/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class LocalPackagesListViewController: UIViewController {

    @IBOutlet private var tableView:UITableView!
    
    fileprivate var localPackages:[AGSMobileMapPackage] = []
    fileprivate var urls:[URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchLocalMMPKs()
    }
    
    private func fetchLocalMMPKs() {
        
        self.localPackages = []
        
        self.urls = []
        
        //documents directory url
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadedDirectoryURL = documentsDirectory.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        
        //filter mmpk urls from documents directory
        if let enumerator = FileManager.default.enumerator(at: downloadedDirectoryURL, includingPropertiesForKeys: nil) {
            
            while let url = enumerator.nextObject() as? URL {
                self.urls.append(url)
            }
        }
        
        //create AGSMobileMapPackage for each url
        for url in urls {
            let package = AGSMobileMapPackage(fileURL: url)
            self.localPackages.append(package)
        }
        
        //reload only if view controller is visible
        if self.isViewLoaded && self.view.window != nil {
            self.tableView.reloadData()
        }
    }
    
    fileprivate func isAlreadyDownloaded(portalItem: AGSPortalItem) -> Bool {
        for url in urls {
            
        }
        
        return true
    }
    
    fileprivate func delete(at url:URL) {
        
        //if FileManager.default.fileExists(atPath: url.absoluteString) {
            try? FileManager.default.removeItem(at: url)
        
        //}
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PackageVCSegue", let controller = segue.destination as? PackageViewController, let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            
            let package = self.localPackages[selectedIndexPath.row]
            controller.mobileMapPackage = package
        }
    }

}

extension LocalPackagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.localPackages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocalPackageCell") as? LocalPackageCell else {
            return UITableViewCell()
        }
        
        cell.mobileMapPackage = self.localPackages[indexPath.row]
        
        return cell
    }
}

extension LocalPackagesListViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //delete package
            let url = self.urls[indexPath.row]
            self.delete(at: url)
            self.urls.remove(at: indexPath.row)
            self.localPackages.remove(at: indexPath.row)
            
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "PackageVCSegue", sender: self)
    }
}
