//
//  LegendInfoCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class LegendInfoCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    
    var legendInfo:AGSLegendInfo? {
        didSet {
            guard let legendInfo = self.legendInfo else {
                return
            }
            
            self.titleLabel.text = legendInfo.name
            
            legendInfo.symbol?.createSwatch { (image, error) in
                guard error == nil else {
                    return
                }
                
                self.thumbnailImageView.image = image
            }
        }
    }
}
