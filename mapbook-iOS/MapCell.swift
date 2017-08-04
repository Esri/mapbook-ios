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
