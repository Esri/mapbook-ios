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

class PortalItemsListViewController: UIViewController {

    @IBOutlet fileprivate var tableView:UITableView!
    @IBOutlet fileprivate var searchBar:UISearchBar!
    @IBOutlet private var footerView:UIView!
    
    private var isLoading = false {
        didSet {
            self.footerView?.isHidden = !isLoading
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 80
        
        self.observeDownloadCompletedNotification()
        
        var keyword:String?
        
        if let urlString = AppContext.shared.portal?.url?.absoluteString, urlString == "https://www.arcgis.com" {
            keyword = "Offline mapbook"
            
            self.searchBar.text = "Offline mapbook"
        }
        self.fetchPortalItems(using: keyword)
    }
    
    fileprivate func fetchPortalItems(using keyword:String?) {
        self.isLoading = true
        
        AppContext.shared.fetchPortalItems(using: keyword) { [weak self] (error, portalItems) in
            
            self?.isLoading = false
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            guard portalItems != nil else {
                return
            }
            
            self?.tableView.reloadData()
        }
    }
    
    fileprivate func fetchMorePortalItems() {
        
        if self.isLoading || !AppContext.shared.hasMorePortalItems() { return }
        
        self.isLoading = true
        
        AppContext.shared.fetchMorePortalItems { [weak self] (error, newPortalItems) in
            
            self?.isLoading = false
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            guard newPortalItems != nil else {
                return
            }
            
            self?.tableView.reloadData()
        }
    }
    
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .DownloadCompleted, object: nil, queue: .main) { [weak self] (notification) in
            
            let error = notification.userInfo?["error"] as? Error
                        
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
            }
            
            if let itemID = notification.userInfo?["itemID"] as? String,
                let index = AppContext.shared.indexOfPortalItem(with: itemID),
                let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PortalItemCell {
                
                cell.isDownloading = false
                
                if error == nil {
                    cell.isAlreadyDownloaded = true
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension PortalItemsListViewController:UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppContext.shared.portalItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PortalItemCell") as? PortalItemCell else {
            return UITableViewCell()
        }
        
        let portalItem = AppContext.shared.portalItems[indexPath.row]
        
        cell.portalItem = portalItem
        cell.isDownloading = AppContext.shared.isCurrentlyDownloading(portalItem: portalItem)
        cell.isAlreadyDownloaded = AppContext.shared.isAlreadyDownloaded(portalItem: portalItem)
        
        return cell
    }
}

extension PortalItemsListViewController:UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //End editing to hide keyboard
        if self.searchBar.isFirstResponder {
            self.searchBar.resignFirstResponder()
        }
        
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        
        let reloadDistance:CGFloat = 100
        
        if h - y < reloadDistance {
            
            self.fetchMorePortalItems()
        }
    }
}

extension PortalItemsListViewController:UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.fetchPortalItems(using: searchBar.text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.fetchPortalItems(using: nil)
        }
    }
}
