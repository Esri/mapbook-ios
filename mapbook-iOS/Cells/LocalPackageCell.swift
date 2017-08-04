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
                
                self?.sizeLabel.text = "Size \(AppContext.shared.size(of: mobileMapPackage) ?? "--")"
                
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
