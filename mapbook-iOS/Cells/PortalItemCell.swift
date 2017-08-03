//
//  PortalItemCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/25/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

protocol PortalItemCellDelegate:class {
    
    func portalItemCell(_ portalItemCell:PortalItemCell, wantsToDownload portalItem:AGSPortalItem)
}

class PortalItemCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var createdLabel:UILabel!
    @IBOutlet private var sizeLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    @IBOutlet private var downloadButton:UIButton!
    @IBOutlet private var activityIndicatorView:UIActivityIndicatorView!
    
    weak var delegate:PortalItemCellDelegate?
    
    var isDownloading = false {
        didSet {
            self.downloadButton.isHidden = isDownloading
            self.activityIndicatorView?.isHidden = !isDownloading
            
            if !(self.activityIndicatorView?.isHidden ?? true) {
                self.activityIndicatorView?.startAnimating()
            }
        }
    }
    
    var isAlreadyDownloaded = false {
        didSet {
            self.downloadButton.isEnabled = !isAlreadyDownloaded
        }
    }
    
    var portalItem:AGSPortalItem? {
        didSet {
            
            guard let portalItemID = portalItem?.itemID else {
                return
            }
            
            self.portalItem?.load { [weak self] (error) in
                
                guard error == nil else {
                    return
                }
                
                guard let portalItem = self?.portalItem, portalItem.itemID == portalItemID else {
                    return
                }

                self?.titleLabel.text = portalItem.title
                
                if let created = portalItem.created {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    self?.createdLabel.text = "Created \(dateFormatter.string(from: created))"
                }
                
                let bytes = ByteCountFormatter().string(fromByteCount: portalItem.size)
                self?.sizeLabel.text = "\(bytes)"
                
                self?.descriptionLabel.text = portalItem.snippet
                
                self?.portalItem?.thumbnail?.load { (error) in
                    
                    guard let portalItem = self?.portalItem, portalItem.itemID == portalItemID else {
                        return
                    }
                    
                    self?.thumbnailImageView.image = self?.portalItem?.thumbnail?.image
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.text = "Title"
        self.createdLabel.text = "Created"
        self.sizeLabel.text = "Size"
        self.descriptionLabel.text = "Description"
        self.thumbnailImageView.image = nil
        self.isDownloading = false
    }
    
    //MARK: -  Actions
    
    @IBAction private func download(_ sender:UIButton) {
        
        guard let portalItem = self.portalItem else {
            return
        }
        
        self.isDownloading = true
        
        self.delegate?.portalItemCell(self, wantsToDownload: portalItem)
        
        
    }
}
