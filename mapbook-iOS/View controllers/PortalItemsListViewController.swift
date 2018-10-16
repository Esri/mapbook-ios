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
        //hide or show footer view with activity indicator
        //based on if loading or not
        didSet {
            self.footerView?.isHidden = !isLoading
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //for self sizing cells
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 80
        
        //observe DownloadCompleted notification to update cell state
        self.observeDownloadCompletedNotification()
        
        //If the portal url is for ArcGIS Online, highlight the offline
        //mapbook we created, using 'Offline mapbook' keyword while fetching
        //portal items.
        var defaultSearch:String?
        
        //So that we can demonstrate Mapbook, we will provide a default search string.
        if let url = AppContext.shared.portal?.url, url == URL.arcGISOnline {
            defaultSearch = "Offline mapbook"
        }
        
        self.searchBar.text = defaultSearch
        self.fetchPortalItems(using: defaultSearch)
    }
    
    /*
     Fetch portal items using keyword. The method calls AppContext's fetch 
     method. And simply refreshes the table view on successful completion
     or displays the error on failure.
    */
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
    
    /*
     Fetch next set of portal items. Again AppContext's fetchMorePortalItems
     method is called. On completion either the error is displayed or table
     view is refreshed.
    */
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
    
    /*
     Convenience method for observing DownloadCompleted notification. In
     the closure, the itemID from userInfo is used to get the corresponding
     cell. The state of the cell is then updated.
    */
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .downloadDidComplete, object: nil, queue: .main) { [weak self] (notification) in
            
            let error = notification.userInfo?["error"] as? Error
                        
            if let error = error as NSError?, error.code != NSUserCancelledError {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            
            if let itemID = notification.userInfo?["itemID"] as? String,
                let index = AppContext.shared.indexOfPortalItem(withItemID: itemID),
                let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PortalItemCell {
                
                cell.isDownloading = false
                
                if error == nil {
                    cell.isAlreadyDownloaded = true
                }
            }
        }
    }
    
    @IBAction func dismissPortalItemsListViewController(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
}

extension PortalItemsListViewController:UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppContext.shared.portalItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PortalItemCell") as? PortalItemCell else {
            return UITableViewCell()
        }
        
        let portalItem = AppContext.shared.portalItems[indexPath.row]
        cell.portalItem = portalItem
        
        return cell
    }
}

extension PortalItemsListViewController:UIScrollViewDelegate {
    
    //Fetch next set of portal items when user scolls to the
    //end of the table view
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

//Search delegate methods
extension PortalItemsListViewController:UISearchBarDelegate {
    
    //fetch portal items using keyword on search bar button click
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //End editing to hide keyboard
        if self.searchBar.isFirstResponder {
            self.searchBar.resignFirstResponder()
        }
        self.fetchPortalItems(using: searchBar.text)
    }
    
    //If the search bar text is empty, fetch portal items without keyword
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.fetchPortalItems(using: nil)
        }
    }
}
