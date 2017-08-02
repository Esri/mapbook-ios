//
//  PackageListViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/24/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
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
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
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
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
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
