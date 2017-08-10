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

class PortalItemCell: UITableViewCell {

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var createdLabel:UILabel!
    @IBOutlet private var sizeLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    @IBOutlet private var downloadButton:UIButton!
    @IBOutlet private var activityIndicatorView:UIActivityIndicatorView!
    
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
            self.downloadButton.isEnabled = !isAlreadyDownloaded
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

                self?.titleLabel.text = portalItem.title
                self?.createdLabel.text = "Created \(AppContext.shared.createdDate(of: portalItem) ?? "--")"
                self?.sizeLabel.text = "\(ByteCountFormatter().string(fromByteCount: portalItem.size))"
                self?.descriptionLabel.text = portalItem.snippet
                
                self?.portalItem?.thumbnail?.load { (error) in
                    
                    guard let portalItem = self?.portalItem, portalItem.itemID == portalItemID else {
                        return
                    }
                    
                    self?.thumbnailImageView.image = self?.portalItem?.thumbnail?.image
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.text = "Title"
        self.createdLabel.text = "Created"
        self.sizeLabel.text = "Size"
        self.descriptionLabel.text = "Description"
        self.thumbnailImageView.image = nil
        self.isDownloading = false
    }
    
    //MARK: -  Actions
    
    @IBAction private func download(_ sender:UIButton) {
        
        guard let portalItem = self.portalItem else {
            return
        }
        
        self.isDownloading = true
        
        AppContext.shared.download(portalItem: portalItem)
    }
}
