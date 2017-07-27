//
//  LocalPackageCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/25/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class LocalPackageCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var createdLabel:UILabel!
    @IBOutlet private var sizeLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    
    var mobileMapPackage:AGSMobileMapPackage? {
        didSet {
            
            self.mobileMapPackage?.load { [weak self] (error) in
                
                guard error == nil else {
                    return
                }
                
                guard let mobileMapPackage = self?.mobileMapPackage, let item = mobileMapPackage.item else {
                    return
                }
                
                if let created = item.created {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    self?.createdLabel.text = "Created \(dateFormatter.string(from: created))"
                }
                
//                let bytes = ByteCountFormatter().string(fromByteCount: item.size)
//                self?.sizeLabel.text = "\(bytes)"
                
                self?.titleLabel.text = item.title
                
                self?.descriptionLabel.text = item.itemDescription
                self?.thumbnailImageView.image = item.thumbnail?.image
                
                item.thumbnail?.load(completion: { (error) in
                    self?.thumbnailImageView.image = item.thumbnail?.image
                    
                    self?.contentView.setNeedsLayout()
                    self?.contentView.layoutIfNeeded()
                })
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
