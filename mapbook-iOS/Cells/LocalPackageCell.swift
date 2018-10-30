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
    @IBOutlet private var downloadedLabel:UILabel!
    @IBOutlet private var updateButton:UIButton!
    @IBOutlet private var activityIndicatorView:UIActivityIndicatorView!
    @IBOutlet private var updateStackView:UIStackView!
        
    var isUpdating = false {
        didSet {
            self.updateButton.isHidden = isUpdating
            self.activityIndicatorView?.isHidden = !isUpdating
            
            if !(self.activityIndicatorView?.isHidden ?? true) {
                self.activityIndicatorView?.startAnimating()
            }
        }
    }
    
    var mobileMapPackage:AGSMobileMapPackage? {
        didSet {
            
            self.mobileMapPackage?.load { [weak self] (error) in
                
                guard let self = self else { return }
                
                guard error == nil else { return }
                
                guard let mobileMapPackage = self.mobileMapPackage,
                    let item = mobileMapPackage.item else {
                    return
                }
                
                self.updateStackView.isHidden = (AppContext.shared.appMode == .device)
                self.isUpdating = AppContext.shared.isUpdating(package: mobileMapPackage)
                self.createdLabel.text = "Created \(AppContext.shared.createdDateAsString(of: item) ?? "--")"
                self.sizeLabel.text = "Size \(AppContext.shared.size(of: mobileMapPackage) ?? "--")"
                self.titleLabel.text = item.title
                self.descriptionLabel.text = item.snippet
                self.thumbnailImageView.image = item.thumbnail?.image
                self.downloadedLabel.text = AppContext.shared.downloadDateAsString(of: mobileMapPackage) ?? "--"
            }
        }
    }
    
    @IBAction private func update() {
        
        guard let package = self.mobileMapPackage else {
            return
        }
        
        guard AppContext.shared.isUpdatable(package: package) else {
            SVProgressHUD.showInfo(withStatus: "\(package.item?.title ?? "The mmpk") is already up to date.")
            return
        }
        
        self.isUpdating = true
        AppContext.shared.update(package: package)
    }
}
