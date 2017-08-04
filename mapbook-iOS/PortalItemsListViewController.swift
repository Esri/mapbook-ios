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
    @IBOutlet private var footerView:UIView!
    
    //fileprivate var downloadingItemIDs:[String] = []
    
    private var isLoading = false {
        didSet {
            self.footerView?.isHidden = !isLoading
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 80
        
        if AppContext.shared.portalItems.count == 0 {
            self.fetchPortalItems()
        }
    }
    
    private func fetchPortalItems() {
        self.isLoading = true
        
        AppContext.shared.fetchPortalItems { [weak self] (error) in
            
            self?.isLoading = false
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            self?.tableView.reloadData()
        }
    }
    
    fileprivate func fetchMorePortalItems() {
        
        if self.isLoading { return }
        
        self.isLoading = true
        
        AppContext.shared.fetchMorePortalItems { [weak self] (error) in
            
            self?.isLoading = false
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            self?.tableView.reloadData()
        }
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
        cell.delegate = self
        cell.isDownloading = AppContext.shared.isCurrentlyDownloading(portalItem: portalItem)
        cell.isAlreadyDownloaded = AppContext.shared.isAlreadyDownloaded(portalItem: portalItem)
        
        return cell
    }
}

extension PortalItemsListViewController:UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
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

extension PortalItemsListViewController: PortalItemCellDelegate {
    
    func portalItemCell(_ portalItemCell: PortalItemCell, wantsToDownload portalItem: AGSPortalItem) {
        
        AppContext.shared.download(portalItem: portalItem) { [weak self, item = portalItem] (error) in
            
            //show error
            if let error = error as NSError?, error.code != NSUserCancelledError {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            
            //even if error, update the state of the cell
            if let index = AppContext.shared.portalItems.index(of: item),
                let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PortalItemCell {
                
                cell.isDownloading = false
                
                if error == nil {
                    cell.isAlreadyDownloaded = true
                }
            }
        }
    }
}
