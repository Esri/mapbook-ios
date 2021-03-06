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

class PortalBrowserViewController: UIViewController {

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

    var packageFinder: PortalPackageSearchManager!
    
    private var portalItems = [AGSPortalItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //for self sizing cells
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 80
        
        //observe DownloadCompleted notification to update cell state
        self.observeDownloadCompletedNotification()
        
        let defaultSearch = AppSettings.defaultPortalBrowserSearchString
        
        self.searchBar.text = defaultSearch
        
        self.fetchPortalItems(using: defaultSearch)
    }
    
    /*
     Fetch portal items using keyword. The method calls AppContext's fetch 
     method. And simply refreshes the table view on successful completion
     or displays the error on failure.
    */
    fileprivate func fetchPortalItems(using keyword: String?) {
        
        guard packageFinder != nil else {
            preconditionFailure("Portal find packages manager should never be nil.")
        }
        
        self.isLoading = true
        
        let params = PortalPackageSearchManager.FindParameters(
            batchSize: AppSettings.portalItemQuerySize ?? 20,
            type: .mobileMapPackage,
            keyword: keyword
        )
        
        do {
            try packageFinder.findPortalItems(params: params) { [weak self] (result) in
                self?.processFindResult(result: result, append: false)
            }
        }
        catch {
            flash(error: error)
        }
    }
        
    /*
     Fetch next set of portal items. Again AppContext's fetchMorePortalItems
     method is called. On completion either the error is displayed or table
     view is refreshed.
    */
    fileprivate func fetchMorePortalItems() {
        
        guard !self.isLoading else { return }
        
        guard packageFinder.canFindMorePortalItems else { return }
        
        self.isLoading = true
        
        do {
            try packageFinder.findMorePortalItems { [weak self] (result) in
                self?.processFindResult(result: result, append: true)
            }
        }
        catch {
            flash(error: error)
        }
    }
    
    private func processFindResult(result: Result<[AGSPortalItem]?, Error>, append: Bool) {
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
                self.tableView.reloadData()
            }
        }
        
        switch result {
            
        case .success(let items):
            if let items = items {
                AGSLoadObjects(items) { (_) in
                    if append {
                        self.portalItems.append(contentsOf: items)
                    }
                    else {
                        self.portalItems = items
                    }
                    
                    for item in items {
                        item.thumbnail?.load { [weak self] (error) in
                            guard let self = self else { return }
                            guard error == nil else { return }
                            self.reloadCell(for: item)
                        }
                    }
                }
            }
            
        case .failure(let error):
            if let error = error as NSError?, error.code != NSUserCancelledError {
                flash(error: error)
            }
        }
    }
    
    private func reloadCell(for item: AGSPortalItem) {
        if let index = portalItems.firstIndex(of: item) {
            let indexPath = IndexPath(row: index, section: 0)
            if tableView.cellForRow(at: indexPath) is PortalItemCell {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }

    /*
     Convenience method for observing DownloadCompleted notification. In
     the closure, the itemID from userInfo is used to get the corresponding
     cell. The state of the cell is then updated.
    */
    private func observeDownloadCompletedNotification() {
        
        NotificationCenter.default.addObserver(forName: .downloadDidComplete, object: nil, queue: .main) { [weak self] (notification) in
            
            guard let self = self else { return }
            
            let error = notification.userInfo?["error"] as? Error
                        
            if let error = error as NSError?, error.code != NSUserCancelledError {
                flash(error: error)
            }
            
            if let itemID = notification.userInfo?["itemID"] as? String,
                let index = self.portalItems.firstIndex(where: { (item) in item.itemID == itemID }),
                let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PortalItemCell,
                let item = cell.portalItem {
                
                do {
                    if try appContext.packageManager.hasDownloaded(item: item) {
                        cell.status = .downloaded
                    }
                    else if appContext.packageManager.isCurrentlyDownloading(item: item.itemID) {
                        cell.status = .downloading
                    }
                    else {
                        cell.status = .cloud
                    }
                }
                catch {
                    cell.status = .unknown
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

extension PortalBrowserViewController:UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return portalItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PortalItemCell") as? PortalItemCell else {
            return UITableViewCell()
        }
        
        let item = portalItems[indexPath.row]
        cell.portalItem = item
        
        do {
            if try appContext.packageManager.hasDownloaded(item: item) {
                cell.status = .downloaded
            }
            else if appContext.packageManager.isCurrentlyDownloading(item: item.itemID) {
                cell.status = .downloading
            }
            else {
                cell.status = .cloud
            }
        }
        catch {
            cell.status = .unknown
        }
        
        return cell
    }
}

extension PortalBrowserViewController:UIScrollViewDelegate {
    
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
extension PortalBrowserViewController:UISearchBarDelegate {
    
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
