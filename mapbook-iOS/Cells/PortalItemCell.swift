//
//  PortalItemCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/25/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

let DownloadedPackagesDirectoryName = "Downloaded packages"

protocol PortalItemCellDelegate:class {
    
    func portalItemCell(_ portalItemCell:PortalItemCell, didStartDownloadingPortalItem itemID:String)
    func portalItemCell(_ portalItemCell:PortalItemCell, didStopDownloadingPortalItem itemID:String)
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
            self.downloadButton.isEnabled = false
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
                
                if let created = portalItem.created {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    self?.createdLabel.text = "Created \(dateFormatter.string(from: created))"
                }
                
                let bytes = ByteCountFormatter().string(fromByteCount: portalItem.size)
                self?.sizeLabel.text = "\(bytes)"
                
                self?.titleLabel.text = portalItem.title
                
                self?.descriptionLabel.text = portalItem.snippet
                
                self?.thumbnailImageView.image = portalItem.thumbnail?.image
                
                self?.portalItem?.thumbnail?.load(completion: { (error) in
                    
                    guard let portalItem = self?.portalItem, portalItem.itemID == portalItemID else {
                        return
                    }
                    
                    self?.thumbnailImageView.image = self?.portalItem?.thumbnail?.image
                    
                })
                
                self?.contentView.setNeedsLayout()
                self?.contentView.layoutIfNeeded()
                
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.text = "Title"
        self.createdLabel.text = "Created"
        self.sizeLabel.text = "Size"
        self.sizeLabel.text = "Description"
        self.thumbnailImageView.image = nil
        self.isDownloading = false
    }
    
    
    fileprivate func downloadPortalItem() {
        
        if self.isDownloading { return }
        
        self.isDownloading = true
        
        let portalItemID = self.portalItem?.itemID ?? ""
        
        //notify delegate
        self.delegate?.portalItemCell(self, didStartDownloadingPortalItem: portalItemID)
        
        self.portalItem?.fetchData { [weak self] (data, error) in
            
            guard let strongSelf = self, let data = data, let portalItem = self?.portalItem else {
                return
            }
            
            //notify delegate
            self?.delegate?.portalItemCell(strongSelf, didStopDownloadingPortalItem: portalItemID)
            
            guard error == nil else {
                print("Error while fetching data!!")
                print(error!)
                return
            }
            
            guard let downloadedDirectoryURL = self?.downloadDirectoryURL() else {
                print("Unable to create directory for downloaded packages")
                return
            }
            
            //TODO: Handle title empty case
            let fileURL = downloadedDirectoryURL.appendingPathComponent("\(portalItemID).mmpk")
            
            print("Starting data write for portalID: \(portalItemID)")
            //TODO: do this on background thread
            try? data.write(to: fileURL, options: Data.WritingOptions.atomic)
            
            print("Finished data write for portalID: \(portalItemID)")
            
            //if the cell is still representing the same portal item
            if portalItem.itemID == portalItemID {
                self?.isDownloading = false
            }
            else {
                print("Cell showing different portal item")
            }
        }
    }
    
    private func downloadDirectoryURL() -> URL? {
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadedDirectoryURL = documentDirectory.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        
        var isDirectory:ObjCBool = false
        if FileManager.default.fileExists(atPath: downloadedDirectoryURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return downloadedDirectoryURL
            }
        }
        
        do {
            try FileManager.default.createDirectory(at: downloadedDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        }
        catch {
            return nil
        }
        
        return downloadedDirectoryURL
    }
    
    //MARK: -  Actions
    
    @IBAction private func download(_ sender:UIButton) {
        
        self.downloadPortalItem()
    }
}
