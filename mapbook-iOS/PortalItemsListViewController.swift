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

    @IBOutlet private var tableView:UITableView!
    @IBOutlet private var footerView:UIView!
    
    private var portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: false)
    fileprivate var downloadingItemIDs:[String] = []
    
    //private var portalItem = AGSPortalItem(url: URL(string: "http://runtime.maps.arcgis.com/home/item.html?id=5ca1aba9eb05490f84b66bf9bbe4cc10")!)
    
    fileprivate var portalItems:[AGSPortalItem] = []
    private var nextQueryParameters:AGSPortalQueryParameters?
    
    private var isLoading = false {
        didSet {
            self.footerView?.isHidden = !isLoading
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 60
        
        self.fetchPortalItems(more: false)
        
    }
    
    fileprivate func fetchPortalItems(more: Bool) {
        
        if self.isLoading { return }
        
        var parameters:AGSPortalQueryParameters
        
        if more {
            guard let nextQueryParameters = self.nextQueryParameters else {
                return
            }
            
            parameters = nextQueryParameters
        }
        else {
            
            self.portalItems = []
            
            parameters = AGSPortalQueryParameters(forItemsOf: .mobileMapPackage, withSearch: nil)
            parameters.limit = 20
        }
        
        self.isLoading = true
        
        self.portal.findItems(with: parameters) { [weak self] (resultSet, error) in
            
            self?.isLoading = false
            
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let portalItems = resultSet?.results as? [AGSPortalItem] else {
                print("No portal items found")
                return
            }
            
            self?.nextQueryParameters = resultSet?.nextQueryParameters
            
            if more {
                self?.portalItems.append(contentsOf: portalItems)
            }
            else {
                self?.portalItems = portalItems
            }
            
            self?.tableView.reloadData()
        }
    }
}

extension PortalItemsListViewController:UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.portalItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PortalItemCell") as? PortalItemCell else {
            return UITableViewCell()
        }
        
        let portalItem = self.portalItems[indexPath.row]
        
        cell.isDownloading = self.downloadingItemIDs.contains(portalItem.itemID)
        
        cell.portalItem = portalItem
        cell.delegate = self
        
        return cell
    }
}

extension PortalItemsListViewController:UITableViewDelegate {
    
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
            
            self.fetchPortalItems(more: true)
        }
    }
}

extension PortalItemsListViewController: PortalItemCellDelegate {
    
    func portalItemCell(_ portalItemCell: PortalItemCell, didStartDownloadingPortalItem itemID: String) {
        
        if !self.downloadingItemIDs.contains(itemID) {
            
            self.downloadingItemIDs.append(itemID)
        }
    }
    
    func portalItemCell(_ portalItemCell: PortalItemCell, didStopDownloadingPortalItem itemID: String) {
        
        if let index = self.downloadingItemIDs.index(of: itemID) {
            self.downloadingItemIDs.remove(at: index)
        }
    }
}
