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

class LegendInfoCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    
    var legendInfo:AGSLegendInfo? {
        didSet {
            
            guard let legendInfo = self.legendInfo else {
                return
            }
            
            //legend name
            self.titleLabel.text = legendInfo.name
            
            //thumbnail
            self.showSwatch(for: legendInfo)
        }
    }
    
    private func showSwatch(for legendInfo:AGSLegendInfo) {
        
        legendInfo.symbol?.createSwatch { [weak self, legendName = legendInfo.name] (image, error) in
            
            guard error == nil else {
                print("Error while creating swatch :: \(error!.localizedDescription)")
                return
            }
            
            guard let legendInfo = self?.legendInfo else {
                return
            }
            
            //if the cell is still representing the same legendInfo
            if legendInfo.name == legendName {
                self?.thumbnailImageView.image = image
            }
        }
    }
}
