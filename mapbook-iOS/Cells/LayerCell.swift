//
//  LayerCell.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class LayerCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var visibilitySwitch:UISwitch!
    
    var operationalLayer:AGSLayer? {
        didSet {
            guard let operationalLayer = self.operationalLayer else {
                return
            }
            
            self.titleLabel.text = operationalLayer.name
            self.visibilitySwitch.isOn = operationalLayer.isVisible
        }
    }
    
    @IBAction private func visibilityChanged(_ sender:UISwitch) {
        
        self.operationalLayer?.isVisible = sender.isOn
    }
}
