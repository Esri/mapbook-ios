//
//  MapCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/18/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class MapCell: UICollectionViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var dateLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = self.isSelected ? UIColor.primaryBlue().withAlphaComponent(0.1) : UIColor.white
        }
    }
    
    var map:AGSMap? {
        didSet {
            guard let item = self.map?.item else {
                return
            }
            
            self.titleLabel?.text = item.title
            self.dateLabel?.text = "date"
            self.descriptionLabel?.text = item.itemDescription
            self.thumbnailImageView.image = item.thumbnail?.image
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        self.thumbnailImageView.layer.cornerRadius = 10
//        self.thumbnailImageView.layer.masksToBounds = true
//    }

}
