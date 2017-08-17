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
    
    //highlight selection
    override var isSelected: Bool {
        didSet {
            self.layer.borderColor = self.isSelected ? UIColor.yellow.cgColor : UIColor.clear.cgColor
            self.layer.borderWidth = self.isSelected ? 1 : 0
        }
    }
    
    var map:AGSMap? {
        didSet {
            guard let item = self.map?.item else {
                return
            }
            
            //update textfields
            self.titleLabel?.text = item.title
            self.dateLabel?.text = "date"
            self.descriptionLabel?.text = item.itemDescription
            self.thumbnailImageView.image = item.thumbnail?.image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //stylize
        self.layer.cornerRadius = 10
    }
}
